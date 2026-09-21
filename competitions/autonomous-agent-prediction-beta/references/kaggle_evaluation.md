name        content                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
----------  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
Evaluation  You must provide a zip archive (`submission.zip`) that contains your Agent Config, comprising system prompts, custom tools, and skills. An `agent.yaml` file must be located at the root of the archive.

```
submission.zip
├── agent.yaml              # Main agent configuration (required)
├── prompts/
│   ├── system.md           # Main system instruction prompt
│   └── subagent_1.md       # Subagent prompts (optional)
├── tools/
│   └── subagent_1.yaml     # Subagent tool definitions (optional)
└── skills/
    └── my-skill/           # Custom skills (optional)
        ├── SKILL.md        # Skill manifest and instructions
        ├── scripts/        # Python or bash scripts executed in a sandbox
        └── resources/      # Domain knowledge markdown files
```

The config language follows the [Google ADK Agent Config](https://adk.dev/agents/config/) specification with additional restrictions to prevent code execution outside of a sandbox. See the [demo notebook](https://www.kaggle.com/code/ryanholbrook/autonomous-agent-prediction-beta-demo-agent) and [sample submission](https://www.kaggle.com/competitions/autonomous-agent-prediction-beta/data?select=sample_submission) for examples. The submissions themselves are compiled into ADK agents to be evaluated.

## The Mini-Competitions ##

Your agent's predictions will be scored by AUC ROC. The agents run in a standard Kaggle CPU environment.  
