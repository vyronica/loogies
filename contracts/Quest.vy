# @version 0.2.16

# Ending task of quest (total number of tasks - 1)
END: constant(uint256) = 2


interface ILoogies:
    def chubbiness(tokenId: uint256) -> uint256:
        view

    def ownerOf(tokenId: uint256) -> address:
        view


struct NewLoogie:
    scar: bool


loogies: public(ILoogies)
tasks: public(HashMap[uint256, HashMap[uint256, bool]])

randomness: uint256

newLoogies: public(HashMap[uint256, NewLoogie])


@external
def __init__(_loogies: address):
    # Deployer is not likely to influence this number, really.
    self.randomness = convert(
        keccak256(
            _abi_encode(
                block.coinbase,
                block.difficulty,
                block.number,
                msg.sender,
                block.timestamp,
            )
        ),
        uint256,
    )

    self.loogies = ILoogies(_loogies)


@internal
def _completeTask(tokenId: uint256, taskId: uint256):
    self.tasks[tokenId][taskId] = True

    if taskId == 0:
        # In the first task, loogie fights with an monster and it can get a scar
        # it completely depends on chubbiness and randomness to get a scar or not.
        scar: bool = convert(self.randomness % self.loogies.chubbiness(tokenId), bool)
        self.newLoogies[tokenId].scar = True
        return


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
    assert self.loogies.ownerOf(tokenId) == msg.sender
    assert taskId < END
    assert not self.tasks[tokenId][taskId]

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
