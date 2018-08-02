module grpc.security.credentials;

import grpc.internal.c_types;

/// A channel credentials object encapsulates all the state needed by a client
/// to authenticate with a server for a given channel.
/// It can make various assertions, e.g., about the client’s identity, role
/// for all the calls on that channel.
///
/// \see https://grpc.io/docs/guides/auth.html
interface ChannelCredentials
{
protected:
    SecureChannelCredentials asSecureCredentials();

private:
    Channel createChannel(string target, ChannelArguments args);
}

/// A call credentials object encapsulates the state needed by a client to
/// authenticate with a server for a given call on a channel.
///
/// \see https://grpc.io/docs/guides/auth.html
interface CallCredentials
{
public:
    bool applyToCall(grpc_call* call);

protected:
    SecureCallCredentials asSecureCredentials();
}

final class SecureChannelCredentials : ChannelCredentials
{
public:
    this(grpc_channel_credentials* c_creds)
    {
        _c_creds = c_creds;
    }

    ~this()
    {
        grpc_channel_credentials_release(_c_creds);
    }

    grpc_channel_credentials* rawCreds()
    {
        return _c_creds;
    }

    override Channel createChannel(string target, ChannelArguments args);
    
    override SecureChannelCredentials asSecureCredentials()
    {
        return this;
    }

private:
    const grpc_channel_credentials* _c_creds;
}

final class SecureCallCredentials : CallCredentials
{
public:
    this(grpc_call_credentials* c_creds)
    {
        _c_creds = c_creds;
    }

    ~this()
    {
        grpc_call_credentials_release(_c_creds);
    }
    
    grpc_call_credentials* rawCredentials()
    {
        return c_creds_;
    }

    override bool applyToCall(grpc_call* call)
    {
        return grpc_call_set_credentials(call, _c_creds) == GRPC_CALL_OK;
    }

    override SecureCallCredentials asSecureCredentials()
    {
        return this;
    }

private:
    const grpc_call_credentials* _c_creds;
}
