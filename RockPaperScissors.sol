// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract RockPaperScissors{
    struct commit{
        bytes32 hashedChoice;
        bool committed;
        bool revealed;
    }

    uint public reward;
    uint public numberOfCommits;
    uint public numberOfReveals;
    uint public waitTime;
    uint public waitCommit;
    uint public waitReveal;
    bool public ended;
    address  firstSender;
    address  secondSender;
    mapping(address => commit) public commits;
    mapping(address => bytes32) public choices;

    // Used to make sure that the commit phase is still on.
    modifier commitPhase{
        require(numberOfCommits <= 2);
        _;
    }

    // Used to make sure that the reveal phase is still on.
    modifier revealPhase{
        require((numberOfCommits == 2) && (numberOfReveals <= 2));
        _;
    }

    // Used to make sure that each sender can make only one commit.
    modifier onlyOneCommit(address sender){
        require(commits[sender].committed == false);
        _;
    }

    // Used to make sure that each sender can make only one reveal.
    modifier onlyOneReveal(address sender){
        require(commits[sender].revealed == false);
        _;
    }

    // Used to make sure that each only the selected people can use the contract.
    modifier onlyAllowed(address sender){
        require(sender == firstSender || sender == secondSender);
        _;
    }

    // Used to check that the wait time for commit has ended.
    modifier onlyAfterCommit(){
        require((block.timestamp > waitCommit && numberOfCommits == 1));
        _;
    }

    // Used to check that the wait time for reveal has ended.
    modifier onlyAfterReveal(){
        require((block.timestamp > waitReveal && numberOfReveals == 1));
        _;
    }

    // Used to check that has not game ended.
    modifier gamedNotEnded(){
        require(ended != true);
        _;
    }

    constructor(address payable senderOne,address payable senderTwo,uint time) payable{
        reward = msg.value;
        firstSender = senderOne;
        secondSender = senderTwo;
        waitTime = time;
    }
    
    // To generate the hashes (for testing).
    function generateHashes(string calldata choice, string calldata secret) external pure 
    returns(bytes32,bytes32){
        bytes32 hashedSecret = keccak256(abi.encode(secret));
        return (hashedSecret,keccak256(abi.encodePacked(choice,hashedSecret)));
    }

    // used to commit the choice during the commit phase.
    function Commit(bytes32 hashedChoice) external 
    gamedNotEnded commitPhase onlyAllowed(msg.sender) onlyOneCommit(msg.sender) {
        commits[msg.sender].hashedChoice = hashedChoice;
        commits[msg.sender].committed = true;
        numberOfCommits +=1;
        if(numberOfCommits == 1){
            waitCommit = block.timestamp + waitTime;
        }
    }

    // reveal the selected choice.
    function reveal(string calldata choice, bytes32 secret) external
    gamedNotEnded revealPhase onlyAllowed(msg.sender) onlyOneReveal(msg.sender){
        if(commits[msg.sender].hashedChoice == keccak256(abi.encodePacked(choice,secret))){
            choices[msg.sender] = keccak256(abi.encodePacked(choice));
            commits[msg.sender].revealed = true;
            numberOfReveals +=1;
        }
        if(numberOfReveals == 2){
            selectWinner();
        }else{
            waitReveal = block.timestamp + waitTime;
        }
    }

    // This is internally called function to select the winner 
    // after both participants have revealed there choices.
    function selectWinner() internal{
        bytes32 rock = keccak256(abi.encodePacked("rock"));
        bytes32 paper = keccak256(abi.encodePacked("paper"));
        bytes32 scissors = keccak256(abi.encodePacked("scissors"));
        if(choices[firstSender] == choices[secondSender]){
            //draw
            uint toPay = reward;
            reward = 0;
            ended = true;
            payable(firstSender).transfer(toPay/2);
            payable(secondSender).transfer(toPay/2);
        }else if(choices[firstSender] == rock && choices[secondSender] == scissors){
            //first won
            uint toPay = reward;
            reward = 0;
            ended = true;
            payable(firstSender).transfer(toPay);
        }else if(choices[firstSender] == paper && choices[secondSender] == rock){
            //first won
            uint toPay = reward;
            reward = 0;
            ended = true;
            payable(firstSender).transfer(toPay);
        }else if(choices[firstSender] == scissors && choices[secondSender] == paper){
            //first won
            uint toPay = reward;
            reward = 0;
            ended = true;
            payable(firstSender).transfer(toPay);
        }else{
            //second won
            uint toPay = reward;
            reward = 0;
            ended = true;
            payable(secondSender).transfer(toPay);
        }
    }

    // Used to end the game by one of the participants in case if one of
    // the two participants did not commit and the wait time for his commit
    // has ended so the participants who commited will reveal his commit
    // and if he revealed correctly he will get the reward.
    function endGameCommit(string calldata choice, bytes32 secret) 
    external gamedNotEnded onlyAfterCommit onlyAllowed(msg.sender){
        if(commits[msg.sender].hashedChoice == keccak256(abi.encodePacked(choice,secret))){
            ended = true;
            uint toPay = reward;
            reward = 0;
            payable(msg.sender).transfer(toPay);
        }
    }

    // Used to end the game by one of the participants in case if one of
    // the two participants did not reveal and the wait time for his reveal
    // has ended so the participants who revealed will get the reward.
    function endGameReveal() external 
    gamedNotEnded onlyAfterReveal onlyAllowed(msg.sender){
        if(commits[msg.sender].revealed == true){
            ended = true;
            uint toPay = reward;
            reward = 0;
            payable(msg.sender).transfer(toPay);
        }
    }
}