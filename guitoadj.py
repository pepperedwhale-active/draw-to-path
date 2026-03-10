from m2syntaxconvert import patideal
import tkinter as tk
import math

class GraphApp:
    def __init__(self, master):
        self.master = master
        master.title("Visual Graph to Adjacency List")

        self.canvas = tk.Canvas(master, width=600, height=400, bg="white")
        self.canvas.pack(fill=tk.BOTH, expand=True)

        self.vertices = {}  # (x, y): label
        self.edges = set()  # (label1, label2)
        self.adj_list = {}  # label: [neighbors]

        self.variablelist = [f'a_{i}' for i in range(1, 100)]
        self.varnumber = 0
        self.next_label = self.variablelist[self.varnumber]
        self.selected_vertex = None

        self.canvas.bind("<Button-1>", self.add_vertex)
        self.canvas.bind("<Shift-Button-1>", self.start_edge)
        self.canvas.bind("<Shift-ButtonRelease-1>", self.finish_edge)
        master.bind("<space>", self.clear_graph)

        self.adj_list_label = tk.Label(master, text="Adjacency List:")
        self.adj_list_label.pack()
        self.adj_list_text = tk.Text(master, height=10, width=40)
        self.adj_list_text.pack()
        self.update_adj_list_display()

    def add_vertex(self, event):
        x, y = event.x, event.y
        if (x, y) not in self.vertices:
            label = self.next_label
            self.vertices[(x, y)] = label
            self.adj_list[label] = []

            self.canvas.create_oval(x - 5, y - 5, x + 5, y + 5, fill="blue")
            self.canvas.create_text(x, y, text=label, fill="white")

            self.varnumber += 1
            if self.varnumber < len(self.variablelist):
                self.next_label = self.variablelist[self.varnumber]
            self.update_adj_list_display()

    def start_edge(self, event):
        x, y = event.x, event.y
        self.selected_vertex = self.get_nearby_label(x, y)

    def finish_edge(self, event):
        x, y = event.x, event.y
        target_vertex = self.get_nearby_label(x, y)
        if self.selected_vertex and target_vertex and self.selected_vertex != target_vertex:
            label1, label2 = sorted([self.selected_vertex, target_vertex])
            if (label1, label2) not in self.edges:
                self.edges.add((label1, label2))
                self.adj_list[label1].append(label2)
                self.adj_list[label2].append(label1)

                pos1 = self.get_coords_by_label(label1)
                pos2 = self.get_coords_by_label(label2)
                self.canvas.create_line(pos1[0], pos1[1], pos2[0], pos2[1], width=2)
                self.update_adj_list_display()
        self.selected_vertex = None

    def get_nearby_label(self, x, y, radius=10):
        for (vx, vy), label in self.vertices.items():
            if math.dist((vx, vy), (x, y)) < radius:
                return label
        return None

    def get_coords_by_label(self, label):
        for (x, y), lbl in self.vertices.items():
            if lbl == label:
                return (x, y)
        return None

    def update_adj_list_display(self):
        self.adj_list_text.delete("1.0", tk.END)
        for vertex, neighbors in self.adj_list.items():
            self.adj_list_text.insert(tk.END, f"{vertex}: {neighbors}\n")
        print(self.adj_list)
        print(patideal(self.adj_list,3))

    def clear_graph(self, event=None):
        self.canvas.delete("all")
        self.vertices = {}
        self.edges = set()
        self.adj_list = {}
        self.varnumber = 0
        self.next_label = self.variablelist[self.varnumber]
        self.selected_vertex = None
        self.update_adj_list_display()


if __name__ == "__main__":
    root = tk.Tk()
    app = GraphApp(root)
    root.mainloop()
