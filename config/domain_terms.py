"""
Domain-specific terms for retrieval boosting.

This module contains domain-specific terms and concepts that can be used to enhance
retrieval performance by boosting domain-relevant terms in search queries.
"""

# Domain-specific terms for retrieval boosting
DOMAIN_TERMS = {
    "leadership": [
        "transformational leadership", "social identity leadership",
        "adaptive leadership", "strategic leadership", "authentic leadership",
        "leader-member exchange", "distributed leadership", "ethical leadership",
        "visionary leadership", "charismatic leadership", "coaching leadership"
    ],
    "group_psychology": [
        "group dynamics", "social identity", "group cohesion", "social facilitation",
        "group polarization", "groupthink", "social loafing", "deindividuation",
        "group development", "team roles", "interpersonal relations", "group norms"
    ],
    "change_management": [
        "change models", "change fatigue", 
        "organizational change", "change readiness", "stakeholder analysis",
        "change resistance", "transition management", "change communication",
        "sustainable change", "change impact analysis"
    ],
    "workshop_facilitation": [
        "facilitation techniques", "workshop design", "participant engagement",
        "icebreakers", "group activities", "brainstorming techniques",
        "consensus building", "decision making methods", "action planning",
        "feedback methods", "workshop evaluation"
    ],
    "negotiation": [
        "BATNA", "ZOPA", "reservation price", "target price", "anchoring",
        "integrative negotiation", "distributive negotiation", "principled negotiation",
        "interest-based bargaining", "positional bargaining", "value creation", "value claiming",
        "negotiation tactics", "concession strategies", "communication styles", "emotional intelligence",
        "cross-cultural negotiation", "power dynamics", "conflict resolution", "persuasion techniques",
        "active listening", "questioning techniques", "non-verbal communication", "closing techniques",
        "handling objections", "building rapport", "ethical considerations", "negotiation preparation",
        "multi-party negotiation", "coalition building", "deadlock resolution", "win-win outcomes"
    ]
}

def get_domain_terms(domain: str) -> list:
    """
    Get domain-specific terms for a given domain.
    
    Args:
        domain: The domain to get terms for
        
    Returns:
        List of domain-specific terms
    """
    return DOMAIN_TERMS.get(domain.lower(), [])
