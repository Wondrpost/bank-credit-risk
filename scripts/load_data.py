import os
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

load_dotenv()
url = URL.create(
    "postgresql+psycopg2",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT")),
    database=os.getenv("DB_NAME"),
)
engine = create_engine(url)

for t in ["account", "client", "disp", "trans", "loan", "card", "order", "district"]:
    df = pd.read_csv(f"data/raw/{t}.csv", sep=";", low_memory=False)
    df.to_sql(t, engine, if_exists="replace", index=False, chunksize=50000)
    print(f"{t}: {len(df)} baris")