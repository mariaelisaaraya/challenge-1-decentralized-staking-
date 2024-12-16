// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negatively impacts submission grading

import "./ExampleExternalContract.sol";

// El contrato verifica quién hizo una apuesta y de cuánto
contract Staker {

  // Eventos
  event Stake(address indexed staker, uint256 amount);
  event DeadlineSet(uint256 deadline);

  ExampleExternalContract public exampleExternalContract;

  // Mapeo para registrar balances individuales
  mapping(address => uint256) public balances;

  // Constantes y variables del contrato
  uint256 public constant threshold = 1 ether; // Umbral
  uint256 public deadline; // Tiempo límite
  bool public openForWithdraw; // Indica si se puede retirar
  bool public executed; // Si el contrato fue ejecutado

  // Constructor: inicializa el contrato
  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    deadline = block.timestamp + 72 hours; // Modificar como dice el reto
    emit DeadlineSet(deadline);
  }

  // Función stake: permite a los usuarios apostar fondos
  function stake() public payable {
    require(block.timestamp < deadline, "Deadline has passed"); // Verifica si la deadline no ha pasado
    balances[msg.sender] += msg.value; // Suma al balance del usuario
    emit Stake(msg.sender, msg.value); // Emite el evento

  }

  // Función execute: permite ejecutar el contrato si se cumple el threshold
  function execute() public {
    require(block.timestamp >= deadline, "Deadline not reached"); // Verifica si el tiempo límite pasó
    require(!executed, "Already executed"); // Verifica si ya fue ejecutado

    if (address(this).balance >= threshold) {
      // Llamamos al contrato externo si se alcanzó el threshold
      exampleExternalContract.complete{value: address(this).balance}();
      executed = true;
    } else {
      // Si no se alcanzó el threshold, se permite el retiro
      openForWithdraw = true;
    }
  }

  // Función withdraw: permite a los usuarios retirar si el threshold no se cumplió
  function withdraw() public {
    require(openForWithdraw, "Not open for withdraw"); // Verifica si el retiro está habilitado
    uint256 balance = balances[msg.sender]; // Obtiene el balance del usuario
    require(balance > 0, "No balance to withdraw"); // Verifica que haya balance

    balances[msg.sender] = 0; // Resetea el balance del usuario
    (bool sent, ) = msg.sender.call{value: balance}(""); // Envía los fondos
    require(sent, "Failed to send Ether"); // Verifica si la transacción fue exitosa
  }

  // Función timeLeft: devuelve el tiempo restante antes de la deadline
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // Función receive: permite recibir ETH directamente
  receive() external payable {
    stake(); // Llama a la función stake()
  }

  // Función getCurrentTime: devuelve el tiempo actual del bloque
  function getCurrentTime() public view returns (uint256) {
    return block.timestamp;
  }

  // Función isExecuted: devuelve si el contrato fue ejecutado
  function isExecuted() public view returns (bool) {
    return executed;
  }
}
