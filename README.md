# matchsticks
a react-powered, 2-player nim-game
___

### what's a nim-game?
[Nim](https://en.wikipedia.org/wiki/Nim) is a game of mathematical strategy, mostly involving subtraction.  As Wikipedia will tell you, players alternatively take objects from 'heaps,' taking as many objects from one heap as they like, but only from one heap per turn.

The **objective of the game** is to leave only one object for the other player to take. In other words: **don't take the last object!**

___
### tech stack & rationale
To make this game, I used a combination of Node, React, Socket.io, and webpack. Node handles the serving of static js, css, and html files, which are transpiled and compiled by webpack.  Socket.io manages the connection between players and emitting events React uses to manage the state of the UI.

The entry point for the game code is [src/js/main.js](https://github.com/ellismarkf/matchsticks/blob/master/src/js/main.js), which iniitalizes the React component. The heart of the game code is in [src/js/components/game.js](https://github.com/ellismarkf/matchsticks/blob/master/src/js/components/game.js) for the UI and [./socketServer.js](https://github.com/ellismarkf/matchsticks/blob/master/socketServer.js) for the back end.

Because the game is for two players, it also has potential application in the online dating world, as a kind of ice breaker for potential matches.  It provides an additional way to interact online that isn't just browsing information or chatting, which is important when trying to learn who a person is.  I also love wordplay, and the idea of an online-dating nim-game called matchsticks was too clever not to make.

___
### running the game
Node developers will already know the drill:

``git clone https://github.com/ellismarkf/matchsticks.git``

then

```
cd matchsticks
npm install
npm start
```
and finally, navigate to ``localhost:5000`` in your browser.  Et voila!

This is a 2-player, socket-based game, so you'll need a friend to play with in another tab on your machine, or if you're both on the same network, on another computer, in which case the second player should navigate to whatever IP address your machine uses, eg ``192.186.1.80:5000``.  Just make sure they're using the right port (``5000``, by default).

Alternatively, you can go to [matchsticks-nim.herokuapp.com](http://matchsticks-nim.herokuapp.com), and play online with a friend.  The same principle applies: both parties must visit the url at the same time before they can start a game.

___
### playing the game

Once two players have arrived at the game, one player should click the ``p1`` button to initialize the game.  The game starts after the second player has joined the game by clicking ``p2``, and immediately lets player 1 take as many sticks from one row as desired.

If a player takes all the sticks from one row, her turn is over, and the other player is free to take objects.  At any point after a player has taken a stick, they are free to end their turn.

The game is over when one player takes the last remaining stick.