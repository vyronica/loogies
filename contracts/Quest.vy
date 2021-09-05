# @version 0.2.16
from vyper.interfaces import ERC20

# Ending task of quest (total number of tasks - 1)
END: constant(uint256) = 2
# Deposit amount required to finish tasks (in LGLD)
DEPOSIT: constant(uint256) = 1000 * 10 ** 18
# Reward amount (in LGLD)
REWARD: constant(uint256) = DEPOSIT / 2


interface ILoogies:
    def chubbiness(tokenId: uint256) -> uint256:
        view

    def ownerOf(tokenId: uint256) -> address:
        view


struct NewLoogie:
    scar: bool
    mustache: bool


# Loogies contract
loogies: public(ILoogies)
# Random number which is determined in the constructor
randomness: uint256
# Tasks completed by a token ID
tasks: public(HashMap[uint256, HashMap[uint256, bool]])
# Traits of new loogie
newLoogies: public(HashMap[uint256, NewLoogie])
# Amount staked as LGLD
balances: public(HashMap[address, uint256])
# LGLD token
lgld: public(ERC20)


@external
def __init__(_loogies: address, _lgld: address):
    # Deployer is not likely to influence this number, really.
    self.randomness = convert(
        keccak256(
            _abi_encode(block.coinbase, block.difficulty, block.number, block.timestamp)
        ),
        uint256,
    )

    self.loogies = ILoogies(_loogies)
    self.lgld = ERC20(_lgld)


@internal
def _updateRandomness():
    self.randomness = convert(
        keccak256(
            _abi_encode(
                block.coinbase,
                block.difficulty,
                block.number,
                block.timestamp,
            )
        ),
        uint256,
    )


@internal
def _completeTask(tokenId: uint256, taskId: uint256):
    self.tasks[tokenId][taskId] = True

    if taskId == 0:
        # In the first task, loogie fights with an monster and it can get a scar
        # it completely depends on chubbiness and randomness to get a scar or not.
        scar: bool = convert(self.randomness % self.loogies.chubbiness(tokenId), bool)
        self.newLoogies[tokenId].scar = scar
        return

    if taskId == 1:
        # Update randomness so you won't get same boolean with previous task
        self._updateRandomness()
        # TODO: Replace deposit amount with half of airdropped LGLD
        # You need to deposit DEPOSIT (specified above) in LGLD for second task.
        assert self.balances[self.loogies.ownerOf(tokenId)] >= DEPOSIT
        mustache: bool = convert(
            self.randomness % self.loogies.chubbiness(tokenId), bool
        )
        self.newLoogies[tokenId].mustache = mustache


@internal
def _additionalTask():
    # TODO: Implement with LGLD and allow LGLD holder to attack loogies?
    pass


@external
def task(tokenId: uint256, taskId: uint256):
    """
    @notice
        Finish quest tasks
    @param tokenId
        Loogies Token ID which you own
    @param taskId
        ID of tasks, starting with 0 and ending with END
    """
    assert (
        self.loogies.ownerOf(tokenId) == msg.sender
    ), "You must be owner of this tokenId"
    assert taskId < END, "Task ID does not exist, try lower task IDs"
    assert not self.tasks[tokenId][taskId], "Task already completed"

    if taskId != 0:
        assert self.tasks[tokenId][taskId - 1], "Complete previous task first"


@external
@view
def finished(tokenId: uint256) -> bool:
    """
    @notice
        Check if tokenId finished quest
    @param tokenId
        Loogies token ID
    @return
        True, if quest is finished
    """
    return self.tasks[tokenId][END]


@external
def deposit():
    """
    @notice
        Deposit LGLD required for taskId 1
    @dev
        You need to give allowance to this contract for LGLD
    """
    assert self.balances[msg.sender] == 0, "Already deposited"
    self.lgld.transferFrom(msg.sender, self, DEPOSIT)


@external
def claim(tokenId: uint256):
    """
    @notice
        Claim LGLD after you finished tasks
    """
    assert (
        self.loogies.ownerOf(tokenId) == msg.sender
    ), "You must be owner of this tokenId"
    assert self.tasks[tokenId][END], "Tasks are not completed"
    self.lgld.transfer(msg.sender, DEPOSIT + REWARD)
