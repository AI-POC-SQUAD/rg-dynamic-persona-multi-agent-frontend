/// Dummy mind map data for the summary page
/// This will be replaced with POST response from backend
class DummyMindMapData {
  /// Get dummy JSON data representing a focus group discussion summary
  ///
  /// The structure represents:
  /// - Central node: The main topic/question
  /// - First level: Key themes/categories identified
  /// - Second level: Specific insights, concerns, or perspectives from personas
  /// - Third level: Supporting details or specific points
  static String getFocusGroupSummary(String topic, List<String> personaNames) {
    return '''
{
  "nodes": [
    {
      "id": "topic",
      "label": "$topic",
      "color": "#535450"
    },
    {
      "id": "interest",
      "label": "Interest & Motivation",
      "color": "#BF046B"
    },
    {
      "id": "concerns",
      "label": "Concerns & Barriers",
      "color": "#F26716"
    },
    {
      "id": "pricing",
      "label": "Pricing Sensitivity",
      "color": "#535450"
    },
    {
      "id": "segments",
      "label": "Key Segments",
      "color": "#BF046B"
    },
    {
      "id": "high_interest",
      "label": "Status-driven commuters (26%)",
      "color": "#F26716"
    },
    {
      "id": "moderate_interest",
      "label": "Convenience buyers (19%)",
      "color": "#BF046B"
    },
    {
      "id": "low_interest",
      "label": "Price-conscious drivers (11%)",
      "color": "#535450"
    },
    {
      "id": "flexibility",
      "label": "Flexibility valued",
      "color": "#F26716"
    },
    {
      "id": "cost_reduction",
      "label": "Initial cost reduction",
      "color": "#BF046B"
    },
    {
      "id": "range_anxiety",
      "label": "Range anxiety solution",
      "color": "#535450"
    },
    {
      "id": "complexity",
      "label": "Added complexity concern",
      "color": "#F26716"
    },
    {
      "id": "ownership",
      "label": "Loss of ownership feeling",
      "color": "#BF046B"
    },
    {
      "id": "long_term_cost",
      "label": "Long-term cost uncertainty",
      "color": "#535450"
    },
    {
      "id": "upfront_price",
      "label": "High upfront price barrier",
      "color": "#F26716"
    },
    {
      "id": "subscription_skepticism",
      "label": "Subscription model skepticism",
      "color": "#BF046B"
    }
  ],
  "edges": [
    {"from": "topic", "to": "interest"},
    {"from": "topic", "to": "concerns"},
    {"from": "topic", "to": "pricing"},
    {"from": "topic", "to": "segments"},
    {"from": "segments", "to": "high_interest"},
    {"from": "segments", "to": "moderate_interest"},
    {"from": "segments", "to": "low_interest"},
    {"from": "interest", "to": "flexibility"},
    {"from": "interest", "to": "cost_reduction"},
    {"from": "interest", "to": "range_anxiety"},
    {"from": "concerns", "to": "complexity"},
    {"from": "concerns", "to": "ownership"},
    {"from": "concerns", "to": "long_term_cost"},
    {"from": "pricing", "to": "upfront_price"},
    {"from": "pricing", "to": "subscription_skepticism"}
  ]
}
''';
  }

  /// Get dummy JSON data in nested format (alternative structure)
  static String getFocusGroupSummaryNested(String topic) {
    return '''
[
  {
    "id": "root",
    "label": "$topic",
    "color": "#535450",
    "children": [
      {
        "id": "positive",
        "label": "Positive Aspects",
        "color": "#BF046B",
        "children": [
          {
            "id": "flexibility",
            "label": "Flexibility in battery options",
            "color": "#FF6B6B"
          },
          {
            "id": "lower_entry",
            "label": "Lower entry cost",
            "color": "#4ECDC4"
          },
          {
            "id": "upgrade_path",
            "label": "Clear upgrade path",
            "color": "#45B7D1"
          }
        ]
      },
      {
        "id": "negative",
        "label": "Challenges",
        "color": "#F26716",
        "children": [
          {
            "id": "complexity",
            "label": "Added complexity",
            "color": "#FFB6C1"
          },
          {
            "id": "ownership_loss",
            "label": "Perceived ownership loss",
            "color": "#FFD700"
          },
          {
            "id": "cost_uncertainty",
            "label": "Long-term cost uncertainty",
            "color": "#FFA07A"
          }
        ]
      },
      {
        "id": "segments",
        "label": "Target Segments",
        "color": "#96CEB4",
        "children": [
          {
            "id": "commuters",
            "label": "Status-driven commuters",
            "color": "#FFEAA7"
          },
          {
            "id": "convenience",
            "label": "Convenience buyers",
            "color": "#DFE6E9"
          },
          {
            "id": "skeptics",
            "label": "Price-conscious skeptics",
            "color": "#74B9FF"
          }
        ]
      }
    ]
  }
]
''';
  }

  /// Get a simple example for testing
  static String getSimpleExample() {
    return '''
{
  "nodes": [
    {"id": "1", "label": "Battery Subscription", "color": "#FF6B6B"},
    {"id": "2", "label": "Pros", "color": "#4ECDC4"},
    {"id": "3", "label": "Cons", "color": "#F26716"},
    {"id": "4", "label": "Lower initial cost", "color": "#45B7D1"},
    {"id": "5", "label": "Flexibility", "color": "#96CEB4"},
    {"id": "6", "label": "Complexity", "color": "#FFEAA7"},
    {"id": "7", "label": "Long-term cost", "color": "#DFE6E9"}
  ],
  "edges": [
    {"from": "1", "to": "2"},
    {"from": "1", "to": "3"},
    {"from": "2", "to": "4"},
    {"from": "2", "to": "5"},
    {"from": "3", "to": "6"},
    {"from": "3", "to": "7"}
  ]
}
''';
  }
}
