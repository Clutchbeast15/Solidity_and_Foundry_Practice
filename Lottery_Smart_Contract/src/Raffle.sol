// Layout of Contract:
// license
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
//SPDX-Licence-Identifier: MIT
pragma solidity 0.8.19;

/*imports*/
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {
    VRFV2PlusClient
} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {
    AutomationCompatibleInterface
} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title Lottery Smart contract
 * @author Vaibhav Sutar
 * @notice This contract is to creating smaple raffle
 * @dev Implements Chainlink VRF2.5
 *
 */
contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /*ERRORS */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    /*Type Declaration*/
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /*`State Variables*/
    uint32 private constant NUM_WORDS = 1; // How many random numbers we want
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // Number of confirmations VRF waits
    uint256 private immutable i_entranceFee; // Cost to enter the raffle
    uint256 private immutable i_interval; // Time gap between raffles
    bytes32 private immutable i_keyHash; // Identifier for VRF gas lane
    uint256 private immutable i_subscriptionId; // Your VRF subscription ID
    uint32 private immutable i_callbackGasLimit; // max gas VRF can use in callback
    address payable[] private s_players; // List of players in the raffle
    uint256 private s_lastTimestamp; // When the last raffle started
    address private s_recentWinner; // Recent winner of the raffle
    RaffleState private s_raffleState;

    /*Events*/
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEntered(address indexed player); // Fired when someone enters the raffle
    event WinnerPicked(address indexed winner); // Fired when a winner is picked

    /* Constructor: runs once when the contract is deployed */
    constructor(
        uint256 entranceFee, // Price to enter raffle
        uint256 interval, // Time between raffles
        address vrfCoordinatorV2, // Address of the Chainlink VRF coordinator
        bytes32 gasLane, // Gas lane for VRF requests
        uint256 subscriptionId, // Chainlink VRF subscription ID
        uint32 callbackGasLimit // Max gas VRF can use during callback
    )
        VRFConsumerBaseV2Plus(vrfCoordinatorV2) // Pass VRF coordinator to base contract

    {
        i_entranceFee = entranceFee; // Set raffle entry cost
        i_interval = interval; // Set how long a raffle lasts
        i_keyHash = gasLane; // Save gas lane for VRF
        i_subscriptionId = subscriptionId; // Save subscription ID
        i_callbackGasLimit = callbackGasLimit; // Save callback gas limit
        s_lastTimestamp = block.timestamp; // Store current timestamp
        s_raffleState = RaffleState.OPEN; // Initialize raffle state to OPEN
    }

    function enterRaffle() external payable {
        //  require(msg.value >= i_entranceFee, "Not Enough Eth sent!");
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            // checks that raffle state is open or not if not then reverts
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        //1. makes migration easier
        //2. makes frontend "indexing" easier
        emit RaffleEntered(msg.sender);
    }

    /* When should the winner be picked?
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * following shoul be ture in order for upkeepNeeded to be ture ;
     * 1. Time interval should have passed
     * 2. At least 1 player should be there
     * 3. The contract should have some ETH
     * 4. Raffle should be in OPEN state
     * @param- ignored
     * @return upkeepNeeded- true if its time to restart the raffle
     * @return- ignored
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimestamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(
        bytes calldata /* performData */
    )
        external
        override
    {
        (bool upkeepNeeded,) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

        // Will revert if subscription is not set and funded.
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit RequestedRaffleWinner(requestId);
    }

    // VRF will call this automatically with the random number(s)
    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] calldata randomWords
    )
        internal
        override
    {
        //Checks

        //Effect (Internal Contract State)
        uint256 inddexOfWinners = randomWords[0] % s_players.length; // Use the random number to pick a winner index from the players list
        address payable recentWinner = s_players[inddexOfWinners]; // Get the address of the selected winner
        s_recentWinner = recentWinner; // Store the winner in state for later use or display

        s_raffleState = RaffleState.OPEN; // Reset the raffle state to OPEN for the next round
        s_players = new address payable[](0); // Clear the players array for the next raffle
        s_lastTimestamp = block.timestamp; // Update the last timestamp to the current time
        emit WinnerPicked(s_recentWinner);

        //Interraction (External Contract)
        (bool success,) = recentWinner.call{value: address(this).balance}(""); // Send all the contract's ETH balance to the winner

        // If the transfer failed, revert the transaction
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
       
        function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }
   
     function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimestamp;
    }

      function getInterval() public view returns (uint256) {
        return i_interval;
    }

    
    // Add to Raffle.sol
function getRecentWinner() external view returns (address) {
    return s_recentWinner;
}


function getNumberOfPlayers() external view returns (uint256) {
    return s_players.length;
}




}
