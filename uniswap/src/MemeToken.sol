// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol"; // 添加这一行
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title MemeToken (Meme代币)
 * @dev 这是由工厂创建的所有Meme币的实现合约。
 * @dev 它使用一个初始化函数来为每个代理设置状态。
 * @dev 铸币过程只能由所有者（即工厂合约）发起。
 */

contract MemeToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    address public factory;

    // 此Meme币的原始创建者（Meme发行者）
    address public creator;

    uint public maxSupply;
    // 每次可铸造数量
    uint public perMint;
    // 单次铸造的价格（单位：wei）
    uint public price;

    // 当前已发行量
    uint public minted;

    // --- 事件 ---
    event Initialized(
        address indexed creator,
        uint256 maxSupply,
        uint256 perMint,
        uint256 price
    );

    function initialize(
        string memory _symbol,
        address _creator,
        uint _maxSupply,
        uint _perMint,
        uint _price
    ) external initializer {


        // 初始化ERC20代币，名称为 "Meme [符号]"
        __ERC20_init(string.concat("Meme ", _symbol), _symbol);
        // 初始化Ownable，将工厂合约设置为所有者
        __Ownable_init();
        creator = _creator;
        maxSupply = _maxSupply;
        perMint = _perMint;
        price = _price;

        // 显式存储工厂地址
        factory = msg.sender;
        emit Initialized(_creator, _maxSupply, _perMint, _price);
    }

    function mint(address _to) external payable {
        require(
            minted + perMint <= maxSupply,
            "MemeToken: Exceeds total supply"
        );
        minted += perMint;
        _mint(_to, perMint);
    }
}
