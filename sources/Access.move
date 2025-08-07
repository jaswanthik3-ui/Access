module jas_addr::AccessTokenSystem {
    use aptos_framework::signer;
    use aptos_framework::timestamp;
    
    struct AccessToken has store, key {
        token_id: u64,           // Unique identifier for the token
        expiration_time: u64,    // Timestamp when token expires
        is_active: bool,         // Status of the token
        operation_type: u64,     // Type of operation this token allows
    }
    
    struct TokenCounter has store, key {
        counter: u64,
    }
    
    const E_TOKEN_NOT_FOUND: u64 = 1;
    const E_TOKEN_EXPIRED: u64 = 2;
    const E_TOKEN_INACTIVE: u64 = 3;
    const E_COUNTER_NOT_INITIALIZED: u64 = 4;
    
    public fun create_access_token(
        owner: &signer, 
        duration_seconds: u64, 
        operation_type: u64
    ) acquires TokenCounter {
        let owner_addr = signer::address_of(owner);
        
        if (!exists<TokenCounter>(owner_addr)) {
            let counter = TokenCounter { counter: 0 };
            move_to(owner, counter);
        };
        
        let current_time = timestamp::now_seconds();
        let expiration_time = current_time + duration_seconds;
        
        let counter = borrow_global_mut<TokenCounter>(owner_addr);
        counter.counter = counter.counter + 1;
        let token_id = counter.counter;
        
        let access_token = AccessToken {
            token_id,
            expiration_time,
            is_active: true,
            operation_type,
        };
        
        move_to(owner, access_token);
    }
    
    public fun validate_and_use_token(
        user: &signer, 
        token_owner: address, 
        expected_operation_type: u64
    ): bool acquires AccessToken {
        assert!(exists<AccessToken>(token_owner), E_TOKEN_NOT_FOUND);
        
        let token = borrow_global_mut<AccessToken>(token_owner);
        
        assert!(token.is_active, E_TOKEN_INACTIVE);
        
        if (token.operation_type != expected_operation_type) {
            return false
        };
        
        let current_time = timestamp::now_seconds();
        if (current_time > token.expiration_time) {
            token.is_active = false;
            return false
        };
        
        token.is_active = false;
        true
    }

}
