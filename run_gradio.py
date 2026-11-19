"""
Launcher cepat untuk menjalankan SkinSight Gradio Prototype dari root workspace.
"""

import sys
from pathlib import Path

# Arahkan ke machine-learning/app_gradio.py
ml_dir = Path(__file__).resolve().parent / "machine-learning"
sys.path.insert(0, str(ml_dir))

from app_gradio import demo

if __name__ == "__main__":
    print("Memulai SkinSight Gradio Prototype...")
    print("Buka browser di: http://127.0.0.1:7860")
    demo.launch(server_name="127.0.0.1", server_port=7860, inbrowser=True)
