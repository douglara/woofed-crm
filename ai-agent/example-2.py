from agno.agent import Agent
from agno.models.groq import Groq
# from agno.tools.tavily import TavilyTools
from agno.tools.yfinance import YFinanceTools

agent = Agent(
    model= Groq(id="llama-3.3-70b-versatile"),
    tools=[YFinanceTools()],
    instructions="Use tabelas para mostrar a informação final. Não inclua nenhum outro texto além da tabela. Se a informação não estiver disponível, responda com 'Informação não disponível'."
)

agent.print_response("Qual é a cotação da ação da Apple?", stream=True)