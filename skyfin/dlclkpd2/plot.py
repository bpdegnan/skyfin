import numpy as np
import matplotlib.pyplot as plt

labels = ['GATE', 'CLK', 'GCLK']
data = np.loadtxt("result.raw")
t = data[:, 0]
plt.figure(figsize=(9, 1.1 * len(labels) + 1))
for s, lab in enumerate(labels):
    plt.plot(t, data[:, 2 * s + 1] + 2.5 * (len(labels) - 1 - s), label=lab)
plt.xlabel("Time (s)"); plt.ylabel("V (stacked)"); plt.title("DLCLKPD2")
plt.legend(loc="upper right"); plt.grid(True); plt.tight_layout()
plt.savefig("dlclkpd2.png", dpi=110); print("wrote dlclkpd2.png")
plt.show()
