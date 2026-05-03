import tkinter as tk
from tkinter import messagebox
import customtkinter as ctk
from pyswip import Prolog

# --- الإعدادات العامة للمظهر ---
ctk.set_appearance_mode("dark")

class TablutGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Aegis - Royal Tablut")
        self.root.geometry("1100x850")
        
        self.prolog = Prolog()
        # تأكدي أن ملف البرولوج بنفس المجلد واسمه game.pl أو غيريه هنا
        try:
            self.prolog.consult("game.pl") 
        except Exception as e:
            print(f"Error loading Prolog: {e}")
        
        self.board_size = 9
        self.selected_tile = None
        self.human_side = 'd' 
        self.difficulty = 'easy'
        self.is_paused = False
        
        self.setup_main_container()
        self.show_start_screen()

    def setup_main_container(self):
        self.main_container = ctk.CTkFrame(self.root, fg_color="#1a1a1a")
        self.main_container.pack(fill="both", expand=True)

    def show_start_screen(self):
        # تنظيف الحاوية الرئيسية
        for widget in self.main_container.winfo_children():
            widget.destroy()
        self.is_paused = False
        
        # إطار شاشة البداية
        start_frame = ctk.CTkFrame(self.main_container, fg_color="#262626", corner_radius=20)
        start_frame.place(relx=0.5, rely=0.5, anchor="center", relwidth=0.6, relheight=0.7)

        ctk.CTkLabel(start_frame, text="ROYAL TABLUT", font=("Cinzel", 45, "bold"), text_color="#FFD700").pack(pady=(40, 20))
        ctk.CTkLabel(start_frame, text="Aegis AI Monitoring System", font=("Arial", 14), text_color="#777").pack(pady=(0, 30))

        # اختيار الجانب
        ctk.CTkLabel(start_frame, text="Select Your Side", font=("Arial", 16, "bold")).pack(pady=5)
        self.side_segment = ctk.CTkSegmentedButton(start_frame, values=["d", "a"], 
                                                  command=lambda v: setattr(self, 'human_side', v),
                                                  selected_color="#FFD700", selected_hover_color="#DAB500")
        self.side_segment.set("d")
        self.side_segment.pack(pady=10)

        # اختيار الصعوبة
        ctk.CTkLabel(start_frame, text="Difficulty Level", font=("Arial", 16, "bold")).pack(pady=5)
        self.level_var = ctk.StringVar(value="easy")
        level_menu = ctk.CTkOptionMenu(start_frame, values=["easy", "medium", "hard"], 
                                      variable=self.level_var, fg_color="#333", button_color="#444")
        level_menu.pack(pady=10)

        # زر Start بتصميم Gradient ذهبي
        start_btn = ctk.CTkButton(start_frame, text="START MISSION", font=("Arial", 18, "bold"),
                                 height=55, width=250, corner_radius=28,
                                 fg_color="#FFD700", text_color="#000", hover_color="#DAB500",
                                 command=self.initiate_game)
        start_btn.pack(pady=50)

    def initiate_game(self):
        self.difficulty = self.level_var.get()
        self.computer_side = 'a' if self.human_side == 'd' else 'd'
        self.setup_game_ui()
        self.start_new_game_prolog()

    def setup_game_ui(self):
        for widget in self.main_container.winfo_children():
            widget.destroy()

        # القائمة الجانبية (Sidebar)
        self.sidebar = ctk.CTkFrame(self.main_container, width=250, corner_radius=0, fg_color="#111")
        self.sidebar.pack(side="left", fill="y")

        ctk.CTkLabel(self.sidebar, text="AEGIS", font=("Cinzel", 28, "bold"), text_color="#FFD700").pack(pady=30)

        # أزرار التحكم
        self.pause_btn = ctk.CTkButton(self.sidebar, text="PAUSE", font=("Arial", 14, "bold"),
                                      fg_color="#A44", hover_color="#822", command=self.toggle_pause)
        self.pause_btn.pack(pady=10, padx=20)
        
        self.resume_btn = ctk.CTkButton(self.sidebar, text="RESUME", font=("Arial", 14, "bold"),
                                       fg_color="#4A4", hover_color="#282", state="disabled", command=self.toggle_pause)
        self.resume_btn.pack(pady=10, padx=20)

        # معلومات اللعبة
        info_text = f"Side: {'Defenders' if self.human_side=='d' else 'Attackers'}\nLevel: {self.difficulty.capitalize()}"
        self.info_label = ctk.CTkLabel(self.sidebar, text=info_text, justify="left", font=("Arial", 13))
        self.info_label.pack(pady=30)

        ctk.CTkButton(self.sidebar, text="Main Menu", fg_color="transparent", border_width=1, 
                     command=self.show_start_screen).pack(side="bottom", pady=30)

        # رقعة اللعب
        self.board_canvas = tk.Canvas(self.main_container, width=600, height=600, bg="#1a1a1a", highlightthickness=0)
        self.board_canvas.pack(pady=50, padx=50)
        self.board_canvas.bind("<Button-1>", self.on_tile_click)

    def toggle_pause(self):
        self.is_paused = not self.is_paused
        if self.is_paused:
            self.pause_btn.configure(state="disabled")
            self.resume_btn.configure(state="normal")
            self.board_canvas.configure(cursor="no")
        else:
            self.pause_btn.configure(state="normal")
            self.resume_btn.configure(state="disabled")
            self.board_canvas.configure(cursor="hand2")

    def start_new_game_prolog(self):
        try:
            res = list(self.prolog.query("initial_board(Board)"))
            if res:
                self.board_data = res[0]['Board']
                self.current_turn = 'human' if self.human_side == 'd' else 'computer'
                self.draw_board()
                if self.current_turn == 'computer':
                    self.root.after(1000, self.computer_move)
        except Exception as e:
            messagebox.showerror("Prolog Error", f"Failed to start: {e}")

    def draw_board(self):
        self.board_canvas.delete("all")
        ts = 600 // self.board_size
        for r in range(self.board_size):
            for c in range(self.board_size):
                color = "#E0E0E0" if (r + c) % 2 == 0 else "#222222"
                if (r, c) == (4, 4) or (r, c) in [(0,0), (0,8), (8,0), (8,8)]:
                    color = "#8B6508" # لون ذهبي للأركان والعرش
                self.board_canvas.create_rectangle(c*ts, r*ts, (c+1)*ts, (r+1)*ts, fill=color, outline="#444")
                self.draw_piece(c*ts, r*ts, self.board_data[r*9+c], ts)

    def draw_piece(self, x, y, piece, size):
        p = 12
        center = size // 2
        if piece == 'k': # التاج الملكي
            self.board_canvas.create_polygon([x+p, y+size-p, x+size-p, y+size-p, x+size-p, y+p+10, x+center, y+center, x+p, y+p+10], 
                                            fill="#FFD700", outline="#000", width=2)
            self.board_canvas.create_oval(x+center-5, y+p-5, x+center+5, y+p+5, fill="#FFD700")
        elif piece == 'd': # المدافعين
            self.board_canvas.create_oval(x+p, y+p, x+size-p, y+size-p, fill="#F0F0F0", outline="#999", width=2)
        elif piece == 'a': # المهاجمين
            self.board_canvas.create_oval(x+p, y+p, x+size-p, y+size-p, fill="#000000", outline="#FFD700", width=1)

    def on_tile_click(self, event):
        if self.is_paused or self.current_turn != 'human': return
        ts = 600 // self.board_size
        col, row = event.x // ts, event.y // ts
        
        if self.selected_tile:
            fr, fc = self.selected_tile
            self.execute_move(fr, fc, row, col)
            self.selected_tile = None
            self.draw_board()
        else:
            piece = self.board_data[row * 9 + col]
            if (self.human_side == 'd' and piece in ['d', 'k']) or (self.human_side == 'a' and piece == 'a'):
                self.selected_tile = (row, col)
                self.board_canvas.create_rectangle(col*ts, row*ts, (col+1)*ts, (row+1)*ts, outline="#00FFFF", width=3)

    def execute_move(self, fr, fc, tr, tc):
        try:
            query = f"valid_move({self.board_data}, move({fr}, {fc}, {tr}, {tc}), Piece), update_board({self.board_data}, move({fr}, {fc}, {tr}, {tc}), NewBoard)"
            res = list(self.prolog.query(query))
            if res:
                self.board_data = res[0]['NewBoard']
                self.draw_board()
                if not self.check_game_over():
                    self.current_turn = 'computer'
                    self.root.after(600, self.computer_move)
            else:
                messagebox.showwarning("Illegal", "This move is not allowed.")
        except:
            messagebox.showerror("Error", "Prolog failed to process move.")

    def computer_move(self):
        if self.is_paused: 
            self.root.after(500, self.computer_move)
            return
        depth = {"easy": 1, "medium": 2, "hard": 3}[self.difficulty]
        try:
            query = f"alphabeta({depth}, ['{self.computer_side}', {self.board_data}], -1001, 1001, [_, NextBoard], _)"
            res = list(self.prolog.query(query))
            if res and 'NextBoard' in res[0]:
                self.board_data = res[0]['NextBoard']
                self.draw_board()
                if not self.check_game_over():
                    self.current_turn = 'human'
            else:
                # إذا لم يجد الكمبيوتر حركة (مثلاً الملك محاصر تماماً)
                self.check_game_over()
        except:
            print("Computer logic failed or timed out.")

    def check_game_over(self):
        try:
            win_res = list(self.prolog.query(f"is_winner({self.board_data}, Winner)"))
            if win_res:
                winner = win_res[0]['Winner']
                msg = "GOLDEN VICTORY! Defenders Win." if winner == 'd' else "DARK DEFEAT! Attackers Win."
                messagebox.showinfo("Game Over", msg)
                self.show_start_screen()
                return True
        except: pass
        return False

if __name__ == "__main__":
    root = ctk.CTk()
    app = TablutGUI(root)
    root.mainloop()
