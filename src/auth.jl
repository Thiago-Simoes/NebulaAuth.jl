
# Função para registrar log de ação.
function log_action(action::String, user)
    ts = string(Dates.now())
    return create(NebulaAuth_Log, Dict("userId"=>user.id, "action"=>action, "timestamp"=>ts))
end

# Altered signup function using module-level NebulaAuth_User.
function signup(email::String, name::String, password::String)
    existing = findFirst(NebulaAuth_User; query=Dict("where" => Dict("email" => email)))
    if existing !== nothing
        error("User already exists")
    end
    uuid = string(UUIDs.uuid4())
    hashed_password = __NEBULA__HashPassword(password)
    ts = string(Dates.now())
    local new_user = create(NebulaAuth_User, Dict(
        "email"      => email,
        "name"       => name,
        "uuid"       => uuid,
        "password"   => hashed_password
    ))
    log_action("signup", new_user)

    # Login
    payload = generateJWT(new_user)

    returnData = Dict(
        "access_token" => payload,
        "token_type" => "Bearer",
        "expiration" => parse(Int, ENV["NEBULAAUTH_JWT_EXP"])*60,
    ) |> JSON3.write

    return new_user, returnData
end

# Altered signin function with password verification.
function signin(email::String, password::String)
    local user = findFirst(NebulaAuth_User; query=Dict("where" => Dict("email" => email)))
    if user === nothing
        error("User not found")
    end
    
    if !__NEBULA__VerifyPassword(password, user.password)
        error("Invalid password")
    end
    log_action("signin", user)

    # Generate JWT token
    payload = generateJWT(user)

    returnData = Dict(
        "access_token" => payload,
        "token_type" => "Bearer",
        "expiration" => parse(Int, ENV["NEBULAAUTH_JWT_EXP"])*60,
    ) |> JSON3.write

    return user, returnData
end

function generateJWT(user)
    payload = Dict("sub" => user.id, "name" => user.name, "email" => user.email, "uuid" => user.uuid, "roles" => getUserRoles(user.id), "permissions" => getUserPermissions(user.id))
    token = __NEBULA__EncodeJWT(payload, ENV["NEBULAAUTH_SECRET"])
    return token
end
