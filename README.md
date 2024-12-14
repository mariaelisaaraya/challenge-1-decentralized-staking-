# Desafío 1: 🔏 Staking Descentralizado

Este repositorio contiene la solución al **Desafío 1: Staking Descentralizado** que verifica el funcionamiento de un contrato inteligente que permite a los usuarios realizar staking de ETH, ejecutar una acción cuando se cumplen condiciones predefinidas, y retirar los fondos si la ejecución no se completa.

## 📚 Descripción General
El contrato **Staker** permite:
1. Que los usuarios realicen **staking** enviando ETH al contrato.
2. Que el contrato **ejecute** una acción si se alcanza un monto mínimo dentro de un tiempo límite.
3. Si el objetivo no se alcanza, los usuarios pueden **retirar** sus fondos.

El proceso se respalda con un contrato adicional **ExampleExternalContract**, que valida la ejecución.

## 🥷 Requisitos del Desafío
- Implementar el contrato inteligente **Staker**.
- Implementar el contrato externo **ExampleExternalContract**.
- Realizar pruebas unitarias para validar los siguientes casos:
  - El staking incrementa correctamente el balance del contrato.
  - Si el tiempo límite se cumple y se alcanza el objetivo, el contrato se ejecuta correctamente.
  - Si el objetivo no se alcanza, los usuarios pueden retirar sus fondos.

## 🛠️ Estructura del Contrato
### Staker.sol

```solidity
pragma solidity ^0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline;
    bool public openForWithdraw;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
        deadline = block.timestamp + 60; // 60 segundos para el testeo
    }

    function stake() public payable {
        require(block.timestamp < deadline, "Deadline has passed");
        balances[msg.sender] += msg.value;
    }

    function execute() public {
        require(block.timestamp >= deadline, "Deadline not reached");
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
            openForWithdraw = false;
        } else {
            openForWithdraw = true;
        }
    }

    function withdraw() public {
        require(openForWithdraw, "Withdrawals not allowed yet");
        uint256 userBalance = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(userBalance);
    }
}
```

### ExampleExternalContract.sol

```solidity
pragma solidity ^0.8.4;

contract ExampleExternalContract {
    bool public completed;

    function complete() public payable {
        completed = true;
    }
}
```

## 🔧 Pruebas Unitarias
Las pruebas unitarias se implementaron usando **Hardhat**. Se validan los siguientes escenarios:

### 1. 🔧 Balance Incrementa al Hacer Staking
- Un usuario realiza una transacción **stake**.
- Se verifica que el balance del contrato aumente en función del monto enviado.

**Log de Prueba:**
```
⚖️ Starting balance: 0
🔨 Staking...
Stake received from: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
Amount staked: 1000000000000000
🛢 New balance: 0.001
👉 Balance should go up when you stake()
```

### 2. ⏳ Ejecución Exitosa
- Se realiza **staking** hasta alcanzar el umbral (1 ETH).
- Se avanza el tiempo límite.
- Se llama a **execute**, y el contrato **ExampleExternalContract** se completa.

**Log de Prueba:**
```
💥 Staking a full eth!
Stake received from: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
🕐 Time should be up now: 0
🎉 calling execute
Contract executed: true
Open for withdraw: false
📤 complete: true
```

### 3. ⚠️ Retiro si No se Alcanza el Umbral
- Se realiza **staking**, pero no se alcanza el umbral.
- Se avanza el tiempo.
- La ejecución falla, y los usuarios pueden **retirar** sus fondos.

**Log de Prueba:**
```
🕐 Time should be up now: 0
🎉 calling execute
Contract executed: false
Open for withdraw: true

💵 calling withdraw
🔍 withdrawResult: 0x926a9a7dd81b...
👉 Should redeploy Staker, stake, not get enough, and withdraw
```

## 📊 Resultados de Gas
El consumo de gas se presenta en los siguientes métodos:

| Contrato   | Método    | Mínimo Gas | Máximo Gas | Promedio |
|------------|-----------|-------------|-------------|----------|
| Staker     | execute   | 49,913      | 83,833      | 66,873   |
| Staker     | stake     | 33,917      | 51,017      | 47,597   |
| Staker     | withdraw  | -           | -           | 30,635   |

## 🌟 Conclusión
El contrato inteligente **Staker** funciona correctamente y cubre los casos de uso esperados:
1. Realizar staking y verificar el balance.
2. Ejecutar correctamente si se alcanza el umbral.
3. Permitir retiros si la ejecución no es exitosa.

Las pruebas unitarias aseguran la correcta implementación de la lógica del contrato, y los resultados de gas muestran un consumo eficiente.
