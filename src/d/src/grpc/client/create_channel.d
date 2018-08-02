module grpc.client.create_channel;

import grpc.channel : Channel;
import grpc.security.credentials : ChannelCredentials;

Channel createChannel(string target, ChannelCredentials creds)
{
    return createCustomChannel(target, creds, ChannelArguments());
}

Channel createCustomChannel(string target, ChannelCredentials creds, ChannelArguments args)
{
    return creds ? creds.createChannel(target, args) : createChannelInternal("",
            grpc_lame_client_channel_create(null,
                GRPC_STATUS_INVALID_ARGUMENT, "Invalid credentials."));
}
