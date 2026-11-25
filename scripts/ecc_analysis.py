import random 
import matplotlib.pyplot as plt

#1. Simulating settings 
FLIT_BITS = 39 # Hamming (39, 32) codeword width 
NUM_FLITS = 10000 # Flits simulated per error state
ber_list = [ 0.001, 0.005, 0.01, 0.02, 0.03, 0.05] # 0.1% TO 5.0%

clean_pct, sec_pct, ded_pct, multi_pct = [], [], [], [] # Lists to store percentages of each error type

#2. Run Monte Carlo bit-flip sweep

print(f"{'BER (%)': <10} {'Clean (%)': <10} {'1-bit heal': <12} {'2-bit heal': <12} {'3+ Uncorr': <10}")

for ber in ber_list:
    clean = sec = ded = multi = 0 # Reset counters 

    for _ in range(NUM_FLITS):
        #Count how many of the 39 bits flipped on the wire
        flips = sum(1 for _ in range(FLIT_BITS) if random.random() < ber)
                     
        if flips == 0:
            clean += 1
        elif flips == 1:
            sec += 1. # Corrected on the fly by SECDED
        elif flips == 2:
            ded += 1 #Flagged as uncorrectable by SECDED
        else:
            multi += 1 #Beyond `2-bit` correction/detection capability
            
    print(f"{ber*100:<10.1f} {clean:<10} {sec:<12} {ded:<12} {multi:<10}")

    clean_pct.append(clean / NUM_FLITS * 100)
    sec_pct.append(sec / NUM_FLITS * 100)
    ded_pct.append(ded / NUM_FLITS * 100)
    multi_pct.append(multi / NUM_FLITS * 100)

#3. Plot the breakdown 
labels = [f"{b*100:.1f}%" for b in ber_list]

plt.figure(figsize=(10, 6))
plt.plot(labels, clean_pct, marker='o', linewidth=2, label='Clean', color='green')
plt.plot(labels, sec_pct, marker='s', linewidth=2, label='1-bit heal', color='blue')
plt.plot(labels, ded_pct, marker='d', linewidth=2, label='2-bit flagged', color='orange')
plt.plot(labels, multi_pct, marker='x', linewidth=2, label='3+ Uncorrectable beyond SECDED capability', color='red')

plt.title('Hamming (39,32) SECDED Fault Tolerance vs Bit Error Rate (BER)  ')
plt.xlabel('Bit Error Rate (BER)')
plt.ylabel('Percentage of Flits (%)')
plt.grid(True, linestyle = '--', alpha = 0.7)
plt.legend()
plt.tight_layout()

plt.savefig('docs/ecc_ber_curve.png', dpi = 300)
print("Plot saved as 'docs/ecc_ber_curve.png'")



