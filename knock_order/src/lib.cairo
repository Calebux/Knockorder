pub mod systems {
    pub mod match_setup;
    pub mod lock_moves;
    pub mod resolve_slot;
    pub mod resolve_round;
    pub mod drain_life;
    pub mod end_round;
    pub mod end_match;
    pub mod init_cards;
}

pub mod models;

pub mod interfaces {
    pub mod IMatchSetup;
    pub mod ILockMoves;
    pub mod IResolveSlot;
    pub mod IResolveRound;
    pub mod IDrainLife;
    pub mod IEndRound;
    pub mod IEndMatch;
    pub mod IInitCards;
}

pub mod base {
    pub mod events;
}

pub mod tests {
    mod test_knock_order;
}
