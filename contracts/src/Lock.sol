// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

contract Lock {
    mapping(address => uint256) public nonces;
    mapping(address => bool)    public unlocked;
    mapping(address => address) public delegates;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant UNLOCK_TYPEHASH = keccak256(
        "Unlock(address user,uint256 nonce,uint256 deadline,address delegate)"
    );

    function unlock(
        address user,
        address delegate,
        uint256 deadline,
        uint8   v,
        bytes32 r,
        bytes32 s
    ) external {
        require(delegate == msg.sender);
        require(block.timestamp <= deadline, "Signature expired");

        bytes32 structHash = keccak256(
            abi.encode(
                UNLOCK_TYPEHASH,
                user,
                nonces[user],  // Prevent replay attacks
                deadline,
                delegate
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        address signer = ecrecover(digest, v, r, s);

        require(signer == user, "Invalid signature");

        nonces[user]++;

        unlocked [user] = true;
        delegates[user] = delegate;
    }

    function lock(address user) external {
        require(delegates[user] == msg.sender);
        require(unlocked[user]);
        unlocked [user] = false;
        delegates[user] = address(0);
    }

    function isUnlocked(address user) external view returns (bool) {
        return unlocked[user] && delegates[user] == msg.sender;
    }

    function increaseNonce() external {
        nonces[msg.sender]++;
    }

    function setDomainSeperator() public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("FUSD_Manager")), 
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }
}