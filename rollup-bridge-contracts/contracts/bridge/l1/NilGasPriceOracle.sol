// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { INilGasPriceOracle } from "./interfaces/INilGasPriceOracle.sol";

// solhint-disable reason-string

contract NilGasPriceOracle is OwnableUpgradeable, INilGasPriceOracle {
  /**********
   * Events *
   **********/

  /// @notice Emitted when current maxFeePerGas is updated.
  /// @param oldMaxFeePerGas The original maxFeePerGas before update.
  /// @param newMaxFeePerGas The current maxFeePerGas updated.
  event MaxFeePerGasUpdated(uint256 oldMaxFeePerGas, uint256 newMaxFeePerGas);

  /// @notice Emitted when current maxPriorityFeePerGas is updated.
  /// @param oldmaxPriorityFeePerGas The original maxPriorityFeePerGas before update.
  /// @param newmaxPriorityFeePerGas The current maxPriorityFeePerGas updated.
  event MaxPriorityFeePerGasUpdated(uint256 oldmaxPriorityFeePerGas, uint256 newmaxPriorityFeePerGas);

  /*************
   * Variables *
   *************/

  /// @notice The latest known maxFeePerGas.
  uint256 public override maxFeePerGas;

  /// @notice The latest known maxPriorityFeePerGas.
  uint256 public override maxPriorityFeePerGas;

  /***************
   * Constructor *
   ***************/

  constructor() {
    _disableInitializers();
  }

  function initialize(address _owner, uint64 _maxFeePerGas, uint64 _maxPriorityFeePerGas) external initializer {
    OwnableUpgradeable.__Ownable_init(_owner);

    maxFeePerGas = _maxFeePerGas;
    maxPriorityFeePerGas = _maxPriorityFeePerGas;
  }

  /*****************************
   * Public Mutating Functions *
   *****************************/

  /// @inheritdoc INilGasPriceOracle
  function setMaxFeePerGas(uint256 newMaxFeePerGas) external onlyOwner {
    uint256 oldMaxFeePerGas = maxFeePerGas;
    maxFeePerGas = newMaxFeePerGas;

    emit MaxFeePerGasUpdated(oldMaxFeePerGas, newMaxFeePerGas);
  }

  /// @inheritdoc INilGasPriceOracle
  function setMaxPriorityFeePerGas(uint256 newMaxPriorityFeePerGas) external onlyOwner {
    uint256 oldMaxPriorityFeePerGas = maxPriorityFeePerGas;
    maxPriorityFeePerGas = newMaxPriorityFeePerGas;

    emit MaxFeePerGasUpdated(oldMaxPriorityFeePerGas, newMaxPriorityFeePerGas);
  }
}
