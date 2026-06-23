import numpy as np
import matplotlib.pyplot as plt

labels = ['A0', 'A1', 'A2', 'A3', 'S0', 'S1', 'X']
data = np.loadtxt("result.raw")
t = data[:, 0]
plt.figure(figsize=(9, 1.1 * len(labels) + 1))
for s, lab in enumerate(labels):
    plt.plot(t, data[:, 2 * s + 1] + 2.5 * (len(labels) - 1 - s), label=lab)
plt.xlabel("Time (s)"); plt.ylabel("V (stacked)"); plt.title("MUX4D4")
plt.legend(loc="upper right"); plt.grid(True); plt.tight_layout()
plt.savefig("mux4d4.png", dpi=110); print("wrote mux4d4.png")
plt.show()
