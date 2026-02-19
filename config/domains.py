"""
Domain Configuration Module

This module defines the available domains and their metadata.
"""

from typing import Dict, List, Optional
from dataclasses import dataclass

@dataclass
class DomainMetadata:
    """Metadata for a knowledge domain."""
    name: str
    description: str
    keywords: List[str]
    parent_domain: Optional[str] = None

# Domain constants
CHANGE_MANAGEMENT = "change_management"
WORKSHOP_FACILITATION = "workshop_facilitation"
LEADERSHIP = "leadership"
NEGOTIATION = "negotiation"
GROUP_PSYCHOLOGY = "group_psychology"

# Domain metadata configuration
DOMAIN_METADATA: Dict[str, DomainMetadata] = {
    CHANGE_MANAGEMENT: DomainMetadata(
        name="Change Management",
        description="Processes and strategies for managing organizational change",
        keywords=["change", "transformation", "transition", "organizational change"],
    ),
    WORKSHOP_FACILITATION: DomainMetadata(
        name="Workshop Facilitation",
        description="Techniques and methods for facilitating effective workshops",
        keywords=["workshop", "facilitation", "group dynamics", "meeting management"],
    ),
    LEADERSHIP: DomainMetadata(
        name="Leadership",
        description="Leadership principles, styles, and practices",
        keywords=["leadership", "management", "team building", "decision making"],
    ),
    NEGOTIATION: DomainMetadata(
        name="Negotiation",
        description="Negotiation, persuasion, and tactical communication",
        keywords=["negotiation", "value", "anchors", "control", "gain"],
    ),
    GROUP_PSYCHOLOGY: DomainMetadata(
        name="Group and Identity Psychology",
        description="Social and group psychology",
        keywords=["tribal", "social", "group", "identity", "values", "outgroup", "ingroup"],
    ),
}

def get_domain_metadata(domain: str) -> Optional[DomainMetadata]:
    """Get metadata for a domain."""
    return DOMAIN_METADATA.get(domain)

def get_all_domains() -> List[str]:
    """Get list of all available domains."""
    return list(DOMAIN_METADATA.keys())

def add_domain_metadata(
    domain_id: str,
    name: str,
    description: str,
    keywords: List[str],
    parent_domain: Optional[str] = None
) -> None:
    """
    Add metadata for a new domain.
    
    Args:
        domain_id: Unique identifier for the domain
        name: Display name of the domain
        description: Description of the domain
        keywords: List of keywords associated with the domain
        parent_domain: Optional parent domain ID
    """
    if domain_id in DOMAIN_METADATA:
        raise ValueError(f"Domain metadata for {domain_id} already exists")
    
    # Add metadata
    DOMAIN_METADATA[domain_id] = DomainMetadata(
        name=name,
        description=description,
        keywords=keywords,
        parent_domain=parent_domain
    ) 