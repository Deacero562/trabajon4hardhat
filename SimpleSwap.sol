// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ILiquidityToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract LiquidityToken is ILiquidityToken {
    string public name = "Liquidity Token";
    string public symbol = "LQT";
    uint8 public decimals = 18;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(to != address(0), "Transfer to zero");
        require(_balances[msg.sender] >= amount, "Balance too low");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "Approve to zero");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(to != address(0), "Transfer to zero");
        require(_balances[from] >= amount, "Balance too low");
        require(_allowances[from][msg.sender] >= amount, "Allowance too low");
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external override {
        require(to != address(0), "Mint to zero");
        require(amount > 0, "Zero mint");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external override {
        require(from != address(0), "Burn from zero");
        require(amount > 0 && _balances[from] >= amount, "Invalid burn");
        _balances[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}

contract SimpleUniswapRouter {
    struct Reserves {
        uint256 reserveA;
        uint256 reserveB;
    }

    mapping(address => mapping(address => Reserves)) private _reserves;
    mapping(address => mapping(address => ILiquidityToken)) private _liquidityTokens;

    uint256 private constant FEE_NUMERATOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;

    function _sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        require(tokenA != tokenB, "Identical tokens");
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function _getLiquidityToken(address tokenA, address tokenB) internal returns (ILiquidityToken) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        if (address(_liquidityTokens[token0][token1]) == address(0)) {
            LiquidityToken lqt = new LiquidityToken();
            _liquidityTokens[token0][token1] = lqt;
            _liquidityTokens[token1][token0] = lqt;
        }
        return _liquidityTokens[token0][token1];
    }

    function getReserves(address tokenA, address tokenB) public view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        Reserves memory r = _reserves[token0][token1];
        if (tokenA == token0) {
            return (r.reserveA, r.reserveB);
        } else {
            return (r.reserveB, r.reserveA);
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(block.timestamp <= deadline, "Expired");
        require(to != address(0), "Zero to");
        require(amountADesired > 0 && amountBDesired > 0, "Amounts zero");

        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1) = getReserves(token0, token1);

        if (reserve0 == 0 && reserve1 == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            uint256 amountBOptimal = (amountADesired * reserve1) / reserve0;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Insufficient B");
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint256 amountAOptimal = (amountBDesired * reserve0) / reserve1;
                require(amountAOptimal >= amountAMin, "Insufficient A");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        ILiquidityToken lqt = _getLiquidityToken(token0, token1);
        uint256 totalSupply = lqt.totalSupply();
        if (totalSupply == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            liquidity = min((amountA * totalSupply) / reserve0, (amountB * totalSupply) / reserve1);
        }

        require(liquidity > 0, "Zero liquidity");
        lqt.mint(to, liquidity);

        _reserves[token0][token1].reserveA = reserve0 + amountA;
        _reserves[token0][token1].reserveB = reserve1 + amountB;
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(block.timestamp <= deadline, "Expired");
        require(to != address(0), "Zero to");
        require(liquidity > 0, "Zero liquidity");

        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        ILiquidityToken lqt = _getLiquidityToken(token0, token1);
        uint256 totalSupply = lqt.totalSupply();
        require(totalSupply > 0, "No liquidity");

        amountA = (liquidity * _reserves[token0][token1].reserveA) / totalSupply;
        amountB = (liquidity * _reserves[token0][token1].reserveB) / totalSupply;

        require(amountA >= amountAMin, "Insufficient A");
        require(amountB >= amountBMin, "Insufficient B");

        lqt.burn(msg.sender, liquidity);
        _reserves[token0][token1].reserveA -= amountA;
        _reserves[token0][token1].reserveB -= amountB;

        IERC20(token0).transfer(to, amountA);
        IERC20(token1).transfer(to, amountB);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        require(amountIn > 0, "Zero amountIn");
        require(reserveIn > 0 && reserveOut > 0, "Zero reserves");
        uint256 amountInWithFee = amountIn * FEE_NUMERATOR / FEE_DENOMINATOR;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn + amountInWithFee;
        return numerator / denominator;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(block.timestamp <= deadline, "Expired");
        require(path.length >= 2, "Invalid path");
        require(to != address(0), "Zero to");

        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint i = 0; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }

        require(amounts[amounts.length - 1] >= amountOutMin, "Insufficient output");

        IERC20(path[0]).transferFrom(msg.sender, address(this), amounts[0]);

        for (uint i = 0; i < path.length - 1; i++) {
            address tokenIn = path[i];
            address tokenOut = path[i + 1];
            (address token0, address token1) = _sortTokens(tokenIn, tokenOut);
            bool isToken0In = tokenIn == token0;

            _reserves[token0][token1].reserveA = isToken0In
                ? _reserves[token0][token1].reserveA + amounts[i]
                : _reserves[token0][token1].reserveA - amounts[i + 1];

            _reserves[token0][token1].reserveB = isToken0In
                ? _reserves[token0][token1].reserveB - amounts[i + 1]
                : _reserves[token0][token1].reserveB + amounts[i];

            if (i == path.length - 2) {
                IERC20(tokenOut).transfer(to, amounts[i + 1]);
            } else {
                IERC20(tokenOut).transfer(address(this), amounts[i + 1]);
            }
        }
    }

    function getPrice(address tokenA, address tokenB) external view returns (uint256 price) {
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB);
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        price = (reserveB * 1e18) / reserveA;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}
