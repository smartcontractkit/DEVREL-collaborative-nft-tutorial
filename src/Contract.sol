// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TLCNFT is VRFConsumerBaseV2, ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface immutable LINKTOKEN;

    Counters.Counter private _tokenIdCounter;

    // Your subscription ID.
    uint64 immutable s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 immutable s_keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 999999;

    // The default is 3, but you can set this higher.
    // uint16 requestConfirmations = 3; // Goerli
    uint16 requestConfirmations = 1; // Fuji

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 public immutable numWords = 2;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    mapping(uint256 => address) public requestIdToAddress;
    uint256 public totalValues = 0;
    mapping(uint256 => uint256[]) public _totalRandomWords;

    uint256 public width = 1920;
    uint256 public height = 1080;
    string headSVG =
        string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 ",
                Strings.toString(width),
                " ",
                Strings.toString(height),
                "' preserveAspectRatio='xMidYMid meet'>",
                "<rect width='",
                Strings.toString(width),
                "' height='",
                Strings.toString(height),
                "' fill='#1C1C1C' />"
            )
        );
    string tailSVG = "</svg>";
    string[] colors = ["#3366FF", "#00FF93", "#FFFFFF"];

    event SpotClaimed(string notification);

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        address link,
        bytes32 keyHash
    )
        VRFConsumerBaseV2(vrfCoordinator)
        ERC721("The Latest Collaborative NFT", "TLCNFT")
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
    }

    function mintNFT(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function claimYourSpot() public {
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        s_randomWords = randomWords;
        _totalRandomWords[totalValues] = randomWords;
        totalValues += 1;
        requestIdToAddress[s_requestId] = msg.sender;
        emit SpotClaimed("Your spot has been claimed!");
    }

    function tokenURI(uint256)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory _bodySVG = "";
        for (uint256 i = 0; i < totalValues; i++) {
            uint256[] memory randomWords = _totalRandomWords[i];
            uint256 shapeNum = randomWords[1] % 3;
            uint256 w = 0;
            if (shapeNum == 0) {
                w = 14;
            } else if (shapeNum == 1) {
                w = 3;
            }
            if (shapeNum == 2) {
                _bodySVG = string(
                    abi.encodePacked(
                        _bodySVG,
                        "<circle cx='",
                        string(Strings.toString(randomWords[0] % width)),
                        "' cy='",
                        string(Strings.toString(randomWords[0] % height)),
                        "' r='7' fill='none' stroke='",
                        colors[randomWords[0] % 3],
                        "' stroke-width='3' />"
                    )
                );
            } else {
                _bodySVG = string(
                    abi.encodePacked(
                        _bodySVG,
                        "<rect x='",
                        string(Strings.toString(randomWords[0] % width)),
                        "' y='",
                        string(Strings.toString(randomWords[0] % height)),
                        "' width='",
                        string(Strings.toString(w)),
                        "' height='14' fill='",
                        colors[randomWords[0] % 3],
                        "' />"
                    )
                );
            }
        }
        string memory _finalSVG = string(
            abi.encodePacked(headSVG, _bodySVG, tailSVG)
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "TLCNFT", ',
                        '"description": "The Latest Collaborative NFT", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(_finalSVG)),
                        '"}'
                    )
                )
            )
        );
        string memory finalTokenURI = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return finalTokenURI;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}
