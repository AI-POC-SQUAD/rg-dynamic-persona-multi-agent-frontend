class Discussion {
  final String id;
  final String title;

  const Discussion({
    required this.id,
    required this.title,
  });

  factory Discussion.fromJson(Map<String, dynamic> json) {
    return Discussion(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}

class MindmapNode {
  final String id;
  final String label;
  final String color;
  final String? tooltip;

  const MindmapNode({
    required this.id,
    required this.label,
    required this.color,
    this.tooltip,
  });

  factory MindmapNode.fromJson(Map<String, dynamic> json) {
    return MindmapNode(
      id: json['id'] as String,
      label: json['label'] as String,
      color: json['color'] as String,
      tooltip: json['tooltip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'color': color,
      if (tooltip != null) 'tooltip': tooltip,
    };
  }
}

class MindmapEdge {
  final String from;
  final String to;

  const MindmapEdge({
    required this.from,
    required this.to,
  });

  factory MindmapEdge.fromJson(Map<String, dynamic> json) {
    return MindmapEdge(
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }
}

class Mindmap {
  final List<MindmapNode> nodes;
  final List<MindmapEdge> edges;

  const Mindmap({
    required this.nodes,
    required this.edges,
  });

  factory Mindmap.fromJson(Map<String, dynamic> json) {
    return Mindmap(
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map(
                  (node) => MindmapNode.fromJson(node as Map<String, dynamic>))
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map(
                  (edge) => MindmapEdge.fromJson(edge as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'edges': edges.map((edge) => edge.toJson()).toList(),
    };
  }
}

class DiscussionDetail {
  final String title;
  final String summary;
  final Mindmap mindmap;

  const DiscussionDetail({
    required this.title,
    required this.summary,
    required this.mindmap,
  });

  factory DiscussionDetail.fromJson(Map<String, dynamic> json) {
    return DiscussionDetail(
      title: json['title'] as String,
      summary: json['summary'] as String,
      mindmap: Mindmap.fromJson(json['mindmap'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'mindmap': mindmap.toJson(),
    };
  }
}
