# ⚔️ Hnefatafl (The Viking Chess) - AI Project

This project is an implementation of the ancient Viking strategy game **Hnefatafl**, developed as part of the **Artificial Intelligence** course at the **Faculty of Computing and AI, Cairo University**.

## 📖 Project Overview
Hnefatafl is a two-player asymmetric strategy game. Unlike traditional chess, the two sides have different numbers of pieces and different objectives:
* **The Defenders (White):** 12 soldiers and a King starting in the center. Their goal is to help the King reach any of the four corner squares to win.
* **The Attackers (Black):** 24 soldiers positioned at the edges. Their goal is to capture the King by surrounding him.

## 💻 Technical Implementation
The game is fully implemented using **Python**. It features a **Human vs. Computer** mode, where the computer's moves are powered by Artificial Intelligence.

### 🧠 AI Engine: Alpha-Beta Pruning
The AI opponent utilizes the **Alpha-Beta Pruning** algorithm to decide on the best moves. The implementation includes:
* **State Representation:** Efficient knowledge representation of the game grid ($9\times9$ or $11\times11$).
* **Utility Function:** A robust evaluation function to calculate the board's strength for each player.
* **Difficulty Levels:** Support for different challenges based on search depth:
    * **Easy:** Depth 1.
    * **Medium:** Depth 3.
    * **Hard:** Depth 5.

## 🎮 Game Rules
* **Movement:** All pieces move like the Rook in chess (horizontally or vertically any number of empty squares).
* **Capturing:** Pieces are captured by "sandwiching" them between two opposing pieces (Custodial Capture).
* **King's Capture:** The attackers win if they surround the King on all four sides, or three sides if he is against a wall.



## 👥 Team Members
* [@Nagham Sabry](https://github.com/NaghamSabry)
* [@Marym Ali](https://github.com/marim55555) 
* [@Seifeldeen Anwar](https://github.com/Seifeldeenanwar) 
* [@Jasmine Mohamed](https://github.com/jasminemohammed1) 
* [@Tibian Tarig](https://github.com/20220943-pixel) 
