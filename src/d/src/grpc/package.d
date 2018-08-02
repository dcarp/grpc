module grpc;

/** 
 * gRPC D API
 *
 * The gRPC D API mainly consists of the following classes:
 * $(BR)
 * $(UL
 * $(LI $(D_PSYMBOL Channel), which represents the connection to an endpoint.
 * See $(LINK2 https://grpc.io/docs/guides/concepts.html, the gRPC Concepts
 * page) for more details. Channels are created by the factory function
 * $(D_PSYMBOL CreateChannel).)

 * $(LI $(D_PSYMBOL CompletionQueue), the producer-consumer queue used for all
 * asynchronous communication with the gRPC runtime.)
 *
 * $(LI $(D_PSYMBOL ClientContext) and $(D_PSYMBOL ServerContext), where
 * optional configuration for an RPC can be set, such as setting custom
 * metadata to be conveyed to the peer, compression settings, authentication,
 * etc.)
 *
 * $(LI $(D_PSYMBOL Server), representing a gRPC server, created by
 * $(D_PSYMBOL ServerBuilder).)
 * )
 *
 * Streaming calls are handled with the streaming classes in
 * $(D_PSYMBOL grpc.sync_stream) and $(D_PSYMBOL grpc.async_stream).
 *
 * Refer to the $(LINK2 https://github.com/grpc/grpc/blob/master/examples/d,
 * examples) for code putting these pieces into play.
*/

public import grpc.channel;
public import grpc.client_context;
public import grpc.completion_queue;
public import grpc.server;
public import grpc.server_context;

string version_()
{
    return "0.1.0";
}
