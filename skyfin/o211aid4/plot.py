import numpy as np
import matplotlib.pyplot as plt

labels = ['A1', 'A2', 'B1', 'C1', 'Y']
data = np.loadtxt("result.raw")
t = data[:, 0]
plt.figure(figsize=(9, 1.1 * len(labels) + 1))
for s, lab in enumerate(labels):
    plt.plot(t, data[:, 2 * s + 1] + 2.5 * (len(labels) - 1 - s), label=lab)
plt.xlabel("Time (s)"); plt.ylabel("V (stacked)"); plt.title("O211AID4")
plt.legend(loc="upper right"); plt.grid(True); plt.tight_layout()
plt.savefig("o211aid4.png", dpi=110); print("wrote o211aid4.png")
plt.show()
