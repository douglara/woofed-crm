from agno.agent import Agent
# from agno.models.openai import OpenAIChat
from agno.models.groq import Groq
from agno.os import AgentOS
from agno.tools.tavily import TavilyTools
from fastapi.middleware.cors import CORSMiddleware

import os
from dotenv import load_dotenv
load_dotenv()

assistant = Agent(
    name="Assistant",
    model=Groq(id="llama-3.3-70b-versatile"),
    tools=[TavilyTools()],
    instructions=["You are a helpful AI assistant.", "Exiba a tabela de resultados de temperatura de uma cidade em formato de tabela markdown."],
    markdown=True,
)

agent_os = AgentOS(
    id="my-first-os",
    description="My first AgentOS",
    agents=[assistant],
)

app = agent_os.get_app()

origins = [
  "*"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if __name__ == "__main__":
    # Default port is 7777; change with port=...
    agent_os.serve(app="main:app", reload=True)
