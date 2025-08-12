
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VirtualRealEstateMarketplace {
    
    struct Property {
        address owner;
        uint256 price;
        bool isForSale;
        string location;
    }
    
    mapping(uint256 => Property) public properties;
    mapping(uint256 => string) public tokenURI;
    
    uint256 public nextTokenId = 1;
    address public contractOwner;
    uint256 public constant FEE = 250; // 2.5%
    
    event PropertyMinted(uint256 tokenId, address owner);
    event PropertySold(uint256 tokenId, address seller, address buyer, uint256 price);
    
    constructor() {
        contractOwner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not owner");
        _;
    }
    
    modifier propertyExists(uint256 tokenId) {
        require(properties[tokenId].owner != address(0), "Property not found");
        _;
    }
    
    function mintProperty(
        address to,
        string memory uri,
        string memory location
    ) external onlyOwner {
        uint256 tokenId = nextTokenId++;
        
        properties[tokenId] = Property({
            owner: to,
            price: 0,
            isForSale: false,
            location: location
        });
        
        tokenURI[tokenId] = uri;
        emit PropertyMinted(tokenId, to);
    }
    
    function listForSale(uint256 tokenId, uint256 price) 
        external 
        propertyExists(tokenId) 
    {
        require(properties[tokenId].owner == msg.sender, "Not your property");
        require(price > 0, "Invalid price");
        
        properties[tokenId].price = price;
        properties[tokenId].isForSale = true;
    }
    
    function buyProperty(uint256 tokenId) 
        external 
        payable 
        propertyExists(tokenId) 
    {
        Property storage prop = properties[tokenId];
        require(prop.isForSale, "Not for sale");
        require(msg.value >= prop.price, "Insufficient funds");
        require(prop.owner != msg.sender, "Cannot buy own property");
        
        address seller = prop.owner;
        uint256 salePrice = prop.price;
        uint256 fee = (salePrice * FEE) / 10000;
        
        prop.owner = msg.sender;
        prop.isForSale = false;
        prop.price = 0;
        
        payable(seller).transfer(salePrice - fee);
        payable(contractOwner).transfer(fee);
        
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }
        
        emit PropertySold(tokenId, seller, msg.sender, salePrice);
    }
    
    function removeFromSale(uint256 tokenId) 
        external 
        propertyExists(tokenId) 
    {
        require(properties[tokenId].owner == msg.sender, "Not your property");
        
        properties[tokenId].isForSale = false;
        properties[tokenId].price = 0;
    }
    
    function getProperty(uint256 tokenId) 
        external 
        view 
        propertyExists(tokenId) 
        returns (Property memory) 
    {
        return properties[tokenId];
    }
}
