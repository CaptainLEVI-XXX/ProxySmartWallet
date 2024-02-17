// SPDX-License-Identifier: Commons-Clause-1.0
pragma solidity ^0.8.13;

library MainStorage {
    bytes32 private constant STORAGE_SLOT = keccak256("com.trymelet.Main");

    error UnauthorizedUpgrade();

    struct Layout {
        /**
         * @dev a transient value to indicate that controller threshold has been reached.
         */
        bool canUpgrade;
    }

    function layout() internal pure returns (Layout storage _layout) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            _layout.slot := slot
        }
    }
}
