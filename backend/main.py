from fastapi import FastAPI, HTTPException
import os
import pandas as pd
from pydantic import BaseModel
from typing import List
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Stats Quiz API")

# --- データ定義（Pydantic） ---
# APIが返すデータの構造を定義し、型安全性を確保
class QuizItem(BaseModel):
    id: int
    context: str
    question: str
    choices: List[str]
    answer: int
    explanation: str

# --- CSV読み込み関数 ---
# 実装力を示すためのPandas操作
def load_quiz_data():
    csv_path = "data/quiz_data.csv"

    if not os.path.exists(csv_path):
        print(f"Error: {csv_path} not found.")
        return []

    try:
        # Pandasで一気に読み込む
        df = pd.read_csv(csv_path)

        # リスト形式に変換（内包表記で実装力をアピール）
        quizzes = []
        for _, row in df.iterrows():
            quizzes.append({
                "id": int(row["id"]),
                "context": str(row["context"]),
                "question": str(row["question"]),
                "choices": [str(row[f"choice_{i}"]) for i in range(1, 6)],
                "answer": int(row["answer"]),
                "explanation": str(row["explanation"])
            })
        return quizzes
    except Exception as e:
        print(f"Loading Error: {e}")
        return []

# --- エンドポイント ---

@app.get("/")
def read_root():
    return {"status": "running", "environment": os.getenv("ENV", "development")}

# クイズ一覧を取得するエンドポイント
@app.get("/quizzes", response_model=List[QuizItem])
def get_all_quizzes():
    data = load_quiz_data()
    if not data:
        raise HTTPException(status_code=404, detail="Quiz data not found")
    return data

# ランダムに1問取得するエンドポイント
@app.get("/quizzes/random", response_model=QuizItem)
def get_random_quiz():
    data = load_quiz_data()
    if not data:
        raise HTTPException(status_code=404, detail="No quizzes available")

    # Pandasを使ってランダムにサンプリング（写経のメインどころ）
    df = pd.DataFrame(data)
    random_quiz = df.sample(n=1).to_dict(orient="records")[0]
    return random_quiz

if __name__ == "__main__":
    import uvicorn
    # 開発環境での実行
    uvicorn.run(app, host="0.0.0.0", port=8000)
