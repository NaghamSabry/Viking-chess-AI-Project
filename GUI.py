import tkinter as tk
from tkinter import messagebox
import customtkinter as ctk
from pyswip import Prolog
import re

ctk.set_appearance_mode("dark")

class TablutGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Aegis - Royal Tablut")
        self.root.geometry("1300x950")
        
        self.prolog = Prolog()
        try:
            self.prolog.consult("game.pl") 
        except Exception as e:
            messagebox.showerror("Prolog Error", f"Could not load game.pl: {e}")
        
        self.board_size = 9
        self.canvas_dim = 800  
        self.selected_tile = None
        self.human_side = 'd' 
        self.difficulty = 'easy'
        self.is_paused = False
        self.board_data = []
        self.current_player = 'a' 
        
        self.setup_main_container()
        self.show_start_screen()

    def setup_main_container(self):
        self.main_container = ctk.CTkFrame(self.root, fg_color="#1a1a1a")
        self.main_container.pack(fill="both", expand=True)

    def show_start_screen(self):
        for widget in self.main_container.winfo_children():
            widget.destroy()
        
        start_frame = ctk.CTkFrame(self.main_container, fg_color="#262626", corner_radius=20)
        start_frame.place(relx=0.5, rely=0.5, anchor="center", relwidth=0.5, relheight=0.6)

        ctk.CTkLabel(start_frame, text="ROYAL TABLUT", font=("Cinzel", 50, "bold"), text_color="#FFD700").pack(pady=(40, 20))
        
        ctk.CTkLabel(start_frame, text="Select Your Side", font=("Arial", 18, "bold")).pack(pady=5)
        self.side_segment = ctk.CTkSegmentedButton(start_frame, values=["d", "a"], 
                                                command=lambda v: setattr(self, 'human_side', v))
        self.side_segment.set("d")
        self.side_segment.pack(pady=10)

        ctk.CTkLabel(start_frame, text="Difficulty Level", font=("Arial", 18, "bold")).pack(pady=5)
        self.level_var = ctk.StringVar(value="easy")
        level_menu = ctk.CTkOptionMenu(start_frame, values=["easy", "medium", "hard"], variable=self.level_var)
        level_menu.pack(pady=10)

        start_btn = ctk.CTkButton(start_frame, text="START MISSION", font=("Arial", 20, "bold"),
                                  height=60, width=300, corner_radius=30,
                                  fg_color="#FFD700", text_color="#000", hover_color="#C9A200", command=self.initiate_game)
        start_btn.pack(pady=40)

    def setup_game_ui(self):
        for widget in self.main_container.winfo_children():
            widget.destroy()

        self.sidebar = ctk.CTkFrame(self.main_container, width=350, corner_radius=0, fg_color="#111")
        self.sidebar.pack(side="left", fill="y")
        self.sidebar.pack_propagate(False)

        ctk.CTkLabel(self.sidebar, text="AEGIS SYSTEM", font=("Cinzel", 32, "bold"), text_color="#FFD700").pack(pady=40)

        self.pause_btn = ctk.CTkButton(self.sidebar, text=" ⏸  PAUSE SYSTEM", font=("Arial", 15, "bold"),
                                      height=50, corner_radius=10,
                                      fg_color="#331a1a", border_color="#A44", border_width=2,
                                      hover_color="#552222", command=self.toggle_pause)
        self.pause_btn.pack(pady=10, padx=30, fill="x")
        
        self.resume_btn = ctk.CTkButton(self.sidebar, text=" ▶  RESUME MISSION", font=("Arial", 15, "bold"),
                                       height=50, corner_radius=10,
                                       fg_color="#1a331a", border_color="#4A4", border_width=2,
                                       state="disabled", hover_color="#225522", command=self.toggle_pause)
        self.resume_btn.pack(pady=10, padx=30, fill="x")

        info_frame = ctk.CTkFrame(self.sidebar, fg_color="#222", corner_radius=15, border_color="#333", border_width=1)
        info_frame.pack(pady=40, padx=20, fill="x")
        
        side_name = 'DEFENDERS' if self.human_side=='d' else 'ATTACKERS'
        info_text = f"PLAYER SIDE: {side_name}\n\nMISSION LEVEL: {self.difficulty.upper()}"
        self.info_label = ctk.CTkLabel(info_frame, text=info_text, justify="left", font=("Consolas", 14), pady=20, text_color="#AAA")
        self.info_label.pack()

        self.back_btn = ctk.CTkButton(self.sidebar, text=" ⬅  EXIT TO BASE", font=("Arial", 14, "bold"),
                                     fg_color="transparent", border_width=1, border_color="#555",
                                     hover_color="#333", height=45,
                                     command=self.show_start_screen)
        self.back_btn.pack(side="bottom", pady=40, padx=30, fill="x")

        self.board_canvas = tk.Canvas(self.main_container, width=self.canvas_dim, height=self.canvas_dim, 
                                      bg="#1a1a1a", highlightthickness=0)
        self.board_canvas.pack(pady=40, padx=40)
        self.board_canvas.bind("<Button-1>", self.on_tile_click)

    def initiate_game(self):
        self.difficulty = self.level_var.get()
        self.computer_side = 'a' if self.human_side == 'd' else 'd'
        self.current_player = 'a'
        self.setup_game_ui()
        self.start_new_game_prolog()

    def start_new_game_prolog(self):
        res = list(self.prolog.query("initial_board(Board)"))
        if res:
            self.board_data = res[0]['Board']
            self.draw_board()
            if self.computer_side == 'a':
                self.root.after(1000, self.computer_move)

    def draw_board(self):
        self.board_canvas.delete("all")
        ts = self.canvas_dim // self.board_size
        for r in range(self.board_size):
            for c in range(self.board_size):
                color = "#E0E0E0" if (r + c) % 2 == 0 else "#222222"
                if (r, c) == (4, 4) or (r, c) in [(0,0), (0,8), (8,0), (8,8)]:
                    color = "#8B6508" 
                self.board_canvas.create_rectangle(c*ts, r*ts, (c+1)*ts, (r+1)*ts, fill=color, outline="#444")
                self.draw_piece(c*ts, r*ts, self.board_data[r*9+c], ts)

    def draw_piece(self, x, y, piece, size):
        p = size // 5
        center = size // 2
        if piece == 'k':
            self.board_canvas.create_oval(x+p, y+p, x+size-p, y+size-p, fill="#FFD700", outline="#000", width=3)
            self.board_canvas.create_text(x+center, y+center, text="♔", font=("Arial", int(size*0.6)), fill="black")
        elif piece == 'd':
            self.board_canvas.create_oval(x+p, y+p, x+size-p, y+size-p, fill="#F0F0F0", outline="#999", width=2)
        elif piece == 'a':
            self.board_canvas.create_oval(x+p, y+p, x+size-p, y+size-p, fill="#000000", outline="#FFD700", width=1)

    def on_tile_click(self, event):
        if self.is_paused or self.current_player != self.human_side: return
        ts = self.canvas_dim // self.board_size
        col, row = event.x // ts, event.y // ts
        
        if self.selected_tile:
            fr, fc = self.selected_tile
            if (fr, fc) == (row, col):
                self.selected_tile = None
                self.draw_board()
            else:
                self.execute_move(fr, fc, row, col)
        else:
            if row < 9 and col < 9:
                piece = self.board_data[row * 9 + col]
                if (self.human_side == 'd' and piece in ['d', 'k']) or (self.human_side == 'a' and piece == 'a'):
                    self.selected_tile = (row, col)
                    self.board_canvas.create_rectangle(col*ts, row*ts, (col+1)*ts, (row+1)*ts, outline="#00FFFF", width=4)

    def execute_move(self, fr, fc, tr, tc):
        try:
            query = f"valid_move({self.board_data}, move({fr}, {fc}, {tr}, {tc}), _), update_board({self.board_data}, move({fr}, {fc}, {tr}, {tc}), NewBoard)"
            res = list(self.prolog.query(query))
            if res:
                self.board_data = res[0]['NewBoard']
                self.selected_tile = None
                self.draw_board()
                if not self.check_game_over():
                    self.current_player = self.computer_side
                    self.root.after(600, self.computer_move)
            else:
                messagebox.showwarning("Invalid Move", "This move is not allowed according to Tablut rules.")
                self.selected_tile = None
                self.draw_board()
        except Exception as e:
            print(f"Move error: {e}")

    def computer_move(self):
        if self.is_paused: 
            self.root.after(500, self.computer_move)
            return
        
        depth_map = {"easy": 1, "medium": 2, "hard": 3}
        d = depth_map.get(self.difficulty, 1)
        self.root.config(cursor="watch")
        self.root.update()

        try:
            query = f"alphabeta({d}, ['{self.computer_side}', {self.board_data}], -1000000, 1000000, Move, _)"
            res = list(self.prolog.query(query))
            
            if res and res[0]['Move'] != 'none':
                move_str = str(res[0]['Move'])
                nums = re.findall(r'\d+', move_str)
                if len(nums) == 4:
                    fr, fc, tr, tc = map(int, nums)
                    upd_query = f"update_board({self.board_data}, move({fr}, {fc}, {tr}, {tc}), NewBoard)"
                    upd_res = list(self.prolog.query(upd_query))
                    if upd_res:
                        self.board_data = upd_res[0]['NewBoard']
                        self.draw_board()
                        if not self.check_game_over():
                            self.current_player = self.human_side
            else:
                messagebox.showinfo("Game Over", "Computer has no valid moves. It's a Draw!")
                self.show_start_screen()
        except Exception as e:
            print(f"AI Error: {e}")
        finally:
            self.root.config(cursor="")

    def check_game_over(self):
        win_res = list(self.prolog.query(f"is_winner({self.board_data}, Winner)"))
        if win_res:
            winner = win_res[0]['Winner']
            w_str = str(winner)
            msg = "VICTORY FOR DEFENDERS!" if w_str == 'd' else "ATTACKERS HAVE CAPTURED THE KING!"
            messagebox.showinfo("MISSION COMPLETE", msg)
            self.show_start_screen()
            return True
        return False

    def toggle_pause(self):
        self.is_paused = not self.is_paused
        if self.is_paused:
            self.pause_btn.configure(state="disabled", border_color="#555")
            self.resume_btn.configure(state="normal", border_color="#4A4")
        else:
            self.pause_btn.configure(state="normal", border_color="#A44")
            self.resume_btn.configure(state="disabled", border_color="#555")

if __name__ == "__main__":
    root = ctk.CTk()
    app = TablutGUI(root)
    root.mainloop()
