import numpy as np
import matplotlib.pyplot as plt

labels = ['CLK', 'D', 'SCD', 'SCE', 'RESET_B', 'Q', 'Q_N']
data = np.loadtxt("result.raw")
t = data[:, 0]
plt.figure(figsize=(9, 1.1 * len(labels) + 1))
for s, lab in enumerate(labels):
    plt.plot(t, data[:, 2 * s + 1] + 2.5 * (len(labels) - 1 - s), label=lab)
plt.xlabel("Time (s)"); plt.ylabel("V (stacked)"); plt.title("SDFRBPD1")
plt.legend(loc="upper right"); plt.grid(True); plt.tight_layout()
plt.savefig("sdfrbpd1.png", dpi=110); print("wrote sdfrbpd1.png")
plt.show()
