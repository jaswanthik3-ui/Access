module jas_addr::AccessTokenSystem {
    use aptos_framework::signer;
    use aptos_framework::timestamp;
    
    /// Struct representing an access token with expiration time.
    struct AccessToken has store, key {
        token_id: u64,           // Unique identifier for the token
        expiration_time: u64,    // Timestamp when token expires
        is_active: bool,         // Status of the token
        operation_type: u64,     // Type of operation this token allows
    }
    
    /// Global counter for generating unique token IDs
    struct TokenCounter has store, key {
        counter: u64,
    }
    
    /// Error codes
    const E_TOKEN_NOT_FOUND: u64 = 1;
    const E_TOKEN_EXPIRED: u64 = 2;
    const E_TOKEN_INACTIVE: u64 = 3;
    const E_COUNTER_NOT_INITIALIZED: u64 = 4;
    
    /// Function to create a new temporary access token
    public fun create_access_token(
        owner: &signer, 
        duration_seconds: u64, 
        operation_type: u64
    ) acquires TokenCounter {
        let owner_addr = signer::address_of(owner);
        
        // Initialize counter if it doesn't exist
        if (!exists<TokenCounter>(owner_addr)) {
            let counter = TokenCounter { counter: 0 };
            move_to(owner, counter);
        };
        
        // Get current timestamp and calculate expiration
        let current_time = timestamp::now_seconds();
        let expiration_time = current_time + duration_seconds;
        
        // Generate unique token ID
        let counter = borrow_global_mut<TokenCounter>(owner_addr);
        counter.counter = counter.counter + 1;
        let token_id = counter.counter;
        
        // Create and store the access token
        let access_token = AccessToken {
            token_id,
            expiration_time,
            is_active: true,
            operation_type,
        };
        
        move_to(owner, access_token);
    }
    
    /// Function to validate and use an access token for operations
    public fun validate_and_use_token(
        user: &signer, 
        token_owner: address, 
        expected_operation_type: u64
    ): bool acquires AccessToken {
        // Check if token exists
        assert!(exists<AccessToken>(token_owner), E_TOKEN_NOT_FOUND);
        
        let token = borrow_global_mut<AccessToken>(token_owner);
        
        // Check if token is active
        assert!(token.is_active, E_TOKEN_INACTIVE);
        
        // Check if token matches the operation type
        if (token.operation_type != expected_operation_type) {
            return false
        };
        
        // Check if token has expired
        let current_time = timestamp::now_seconds();
        if (current_time > token.expiration_time) {
            token.is_active = false;
            return false
        };
        
        // Token is valid - deactivate it after use (single-use token)
        token.is_active = false;
        true
    }
}