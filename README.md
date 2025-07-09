# 🔁 SimpleSwap - Contrato Inteligente (Hardhat + Testing)

Este repositorio contiene el contrato inteligente `SimpleSwap` que simula una DEX (Decentralized Exchange) al estilo Uniswap, permitiendo intercambios entre dos tokens ERC20 (`Token A` y `Token B`) y gestión de liquidez. Incluye además pruebas automatizadas utilizando Hardhat.

---

## 📂 Estructura del proyecto

simple-swap/
├── contracts/
│   ├── TokenA.sol             # Token ERC20 A
│   ├── TokenB.sol             # Token ERC20 B
│   └── SimpleSwap.sol         # Contrato principal de intercambio
│
├── test/
│   └── SimpleSwap.test.js     # Pruebas unitarias con Hardhat
│
├── scripts/
│   └── deploy.js              # Script de despliegue en la red
│
├── hardhat.config.js          # Configuración de Hardhat
├── package.json               # Dependencias del proyecto
├── README.md                  # Documentación del proyecto
└── .env                       # Variables de entorno (NO subir al repo)


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

    ✅ Testing con Hardhat

    ✅ 50%+ de cobertura con npx hardhat coverage

    ✅ Repositorio en GitHub

📬 Contacto

Autor: @Deacero562
