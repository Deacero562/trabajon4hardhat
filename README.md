# 🔁 SimpleSwap - Contrato Inteligente (Hardhat + Testing)

Este repositorio contiene el contrato inteligente `SimpleSwap` que simula una DEX (Decentralized Exchange) al estilo Uniswap, permitiendo intercambios entre dos tokens ERC20 (`Token A` y `Token B`) y gestión de liquidez. Incluye además pruebas automatizadas utilizando Hardhat.

---

## 📂 Estructura del proyecto

simple-swap/
├── contracts/
│ ├── TokenA.sol
│ ├── TokenB.sol
│ └── SimpleSwap.sol
├── test/
│ └── SimpleSwap.test.js
├── scripts/
│ └── deploy.js
├── hardhat.config.js
├── package.json
├── README.md

---

## ⚙️ Requisitos previos

- Node.js y npm
- [Hardhat](https://hardhat.org/)
- GitHub Codespaces o entorno local
- Cuenta MetaMask y red Sepolia configurada

---

🧪 Ejecución de tests

Para correr las pruebas de unidad y obtener la cobertura:

npx hardhat test
npx hardhat coverage

🔎 Cobertura alcanzada: ✅ más del 50% según requerimientos del módulo 4.
🧠 Funcionalidades clave del contrato

    addLiquidity: agregar liquidez entre Token A y B.

    removeLiquidity: quitar liquidez.

    swapExactTokensForTokens: intercambiar tokens.

    getPrice: obtener el precio de un token en función del otro.

    Internamente gestiona LiquidityToken como un mini LP token ERC20.

✅ Requisitos cumplidos

    ✅ Interacción con el contrato desde frontend (ver index.html en GitHub Pages)

    ✅ Testing con Hardhat

    ✅ 50%+ de cobertura con npx hardhat coverage

    ✅ Recomendaciones del instructor implementadas

    ✅ Repositorio en GitHub

    ✅ Despliegue en Sepolia

    ✅ Conexión a wallet desde front-end

    ✅ Swaps y liquidez operativos

📬 Contacto

Autor: @Deacero562
