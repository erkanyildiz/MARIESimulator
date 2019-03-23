# MARIESimulator
## MARIE  
MARIE (Machine Architecture that is Really Intuitive and Easy) is an easily comprehensible virtual computer architecture, specially created for computer organization/architecture/design class students.

## Simulator  
MARIESimulator is an iPad application written in Objective-C, and its interface is like shown below:
 
![](https://raw.githubusercontent.com/erkanyildiz/MARIESimulator/master/MARIESimulator/mariesimulator_screenshot.png)


## Interface      
`SOURCE` textfield is for entering MARIE source code.

`RAM` section is for displaying addresses and contents of memory.

`REGISTER` section is for displaying contents of registers. `INREG` textfield is used for `INPUT` instruction.

`LABELS` section is for displaying labels and their address equivalents in the source code.

`LOAD` button processes the MARIE source code in the `SOURCE` field, detects labels and displays them in the `LABELS` section, and fills the `RAM` section according to the instructions and labels.

`RUN` button starts and countinues executing instructions automatically and displays the new values in `REGISTER` and `RAM` sections until `HALT` instruction is executed.

`STEP` button executes instructions line by line.

`EXAMPLE` buttons are for filling `SOURCE` textfield with some example MARIE codes.

`[210-22F]` button fills addresses between `210` and `22F` on memory with random values which are required for Example 2.

`[350-36F]` button fills addresses between `350` and `36F` on memory with random values which are required for Example 3.
