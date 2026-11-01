"""Shared native render-list/UI mapping, Python 2.7 and 3 compatible."""
PHASES = {'panel-ready', 'panel-submit', 'panel-cleanup', 'gameover-tail'}


def canonical(rows, panel_ids=()):
    panel_ids = set(panel_ids)
    lists = {}
    for row in rows:
        f = row.split('\t')
        if f[0] == 'R' and f[2] in PHASES:
            lists.setdefault(f[2], []).append(f)
    for phase, nodes in lists.items():
        for i, node in enumerate(nodes):
            assert node[4] == (nodes[i-1][3] if i else '0'), (phase, 'previous link', node[3])
            assert node[5] == (nodes[i+1][3] if i+1 < len(nodes) else '0'), (phase, 'next link', node[3])
    indexes = {phase: {node[3]: node for node in nodes} for phase, nodes in lists.items()}
    def render_id(value):
        # Native's shared allocator counts the three UI births; host's world allocator does not.
        return str(int(value) - sum(int(p) < int(value) for p in panel_ids))
    output = []
    for row in rows:
        fields = row.split('\t')
        if fields[0] == 'R' and fields[2] in PHASES:
            if fields[3] in panel_ids:
                continue  # UI state is compared separately through U/F records.
            for direction in (4, 5):
                visited = set()
                while fields[direction] in panel_ids:
                    assert fields[direction] not in visited, 'UI list cycle'
                    visited.add(fields[direction])
                    fields[direction] = indexes[fields[2]][fields[direction]][direction]
                fields[direction] = render_id(fields[direction])
            fields[3] = render_id(fields[3])
        if fields[0] == 'E' and fields[2] in PHASES:
            assert fields[4] not in panel_ids, 'entity references UI sprite'
            fields[4] = render_id(fields[4])
        if fields[0] in {'G', 'E', 'R', 'S'}:
            fields[1] = 'T'  # Diagnostic annotation, not a game-state clock.
        output.append('\t'.join(fields))
    return output
