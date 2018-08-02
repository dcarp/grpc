module grpc.client_context;

import std.datetime : SysTime;
import std.typecons : BitFlags;

import grpc.internal.auth_context;
import grpc.internal.c_types;
import grpc.server_context;

/// Options for \a ClientContext::FromServerContext specifying which traits from
/// the \a ServerContext to propagate (copy) from it into a new \a
/// ClientContext.
///
/// \see ClientContext::FromServerContext
struct PropagationOptions
{
    enum PropagationBits : uint
    {
        deadline = 1 << 0,
        censusStatsContext = 1 << 1,
        censusTracingContext = 1 << 2,
        cancellation = 1 << 3,
    }

    BitFlags!PropagationBits _propagate = PropagationBits.deadline | PropagationBits.censusStatsContext
        | PropagationBits.censusTracingContext | PropagationBits.cancellation;

public:
        PropagationOptions enableDeadlinePropagation()
    {
        _propagate |= PropagationBits.deadline;
        return *this;
    }

    PropagationOptions disableDeadlinePropagation()
    {
        _propagate &= ~PropagationBits.deadline;
        return *this;
    }

    PropagationOptions enableCensusStatsPropagation()
    {
        _propagate |= PropagationBits.censusStatsContext;
        return *this;
    }

    PropagationOptions disableCensusStatsPropagation()
    {
        _propagate &= ~PropagationBits.censusStatsContext;
        return *this;
    }

    PropagationOptions enableCensusTracingPropagation()
    {
        _propagate |= PropagationBits.censusTracingContext;
        return *this;
    }

    PropagationOptions disableCensusTracingPropagation()
    {
        _propagate &= ~PropagationBits.censusTracingContext;
        return *this;
    }

    PropagationOptions enableCancellationPropagation()
    {
        _propagate |= PropagationBits.cancellation;
        return *this;
    }

    PropagationOptions disableCancellationPropagation()
    {
        _propagate &= ~PropagationBits.cancellation;
        return *this;
    }

    uint bitmask() const
    {
        return 0xffff & _propagate;
    }
}

/// A ClientContext allows the person implementing a service client to:
///
/// - Add custom metadata key-value pairs that will propagated to the server
///   side.
/// - Control call settings such as compression and authentication.
/// - Initial and trailing metadata coming from the server.
/// - Get performance metrics (ie, census).
///
/// Context settings are only relevant to the call they are invoked with, that
/// is to say, they aren't sticky. Some of these settings, such as the
/// compression options, can be made persistent at channel construction time
/// (see \a grpc::CreateCustomChannel).
///
/// \warning ClientContext instances should \em not be reused across rpcs.
class ClientContext
{
public:
    this()
    {
    }

    ~this()
    {
    }

    /// Create a new \a ClientContext as a child of an incoming server call,
    /// according to \a options (\see PropagationOptions).
    ///
    /// \param server_context The source server context to use as the basis for
    /// constructing the client context.
    /// \param options The options controlling what to copy from the \a
    /// server_context.
    ///
    /// \return A newly constructed \a ClientContext instance based on \a
    /// server_context, with traits propagated (copied) according to \a options.
    static ClientContext fromServerContext(const ServerContext serverContext,
            PropagationOptions options = PropagationOptions())
    {
    }

    /// Add the (\a meta_key, \a meta_value) pair to the metadata associated with
    /// a client call. These are made available at the server side by the \a
    /// grpc::ServerContext::client_metadata() method.
    ///
    /// \warning This method should only be called before invoking the rpc.
    ///
    /// \param meta_key The metadata key. If \a meta_value is binary data, it must
    /// end in "-bin".
    /// \param meta_value The metadata value. If its value is binary, the key name
    /// must end in "-bin".
    void addMetadata(string metaKey, string metaValue)
    {
    }

    /// Return a collection of initial metadata key-value pairs. Note that keys
    /// may happen more than once (ie, a \a std::multimap is returned).
    ///
    /// \warning This method should only be called after initial metadata has been
    /// received. For streaming calls, see \a
    /// ClientReaderInterface::WaitForInitialMetadata().
    ///
    /// \return A multimap of initial metadata key-value pairs from the server.
    string[][string] serverInitialMetadata() const
    {
        assert(_initialMetadataReceived);
        return _receivedInitialMetadata;
    }

    /// Return a collection of trailing metadata key-value pairs. Note that keys
    /// may happen more than once (ie, a \a std::multimap is returned).
    ///
    /// \warning This method is only callable once the stream has finished.
    ///
    /// \return A multimap of metadata trailing key-value pairs from the server.
    string[][string] serverTrailingMetadata() const
    {
        return _trailingMetadata;
    }

    /// Set the deadline for the client call.
    ///
    /// \warning This method should only be called before invoking the rpc.
    ///
    /// \param deadline the deadline for the client call. Units are determined by
    /// the type used.
    @property void deadline(SysTime deadline)
    {
        _deadline = deadline;
    }

    /// Return the deadline for the client call.
    @property SysTime deadline() const
    {
        return _deadline;
    }

    /// EXPERIMENTAL: Indicate that this request is idempotent.
    /// By default, RPCs are assumed to <i>not</i> be idempotent.
    ///
    /// If true, the gRPC library assumes that it's safe to initiate
    /// this RPC multiple times.
    @property void idempotent(bool idempotent)
    {
        _idempotent = idempotent;
    }

    /// EXPERIMENTAL: Set this request to be cacheable.
    /// If set, grpc is free to use the HTTP GET verb for sending the request,
    /// with the possibility of receiving a cached response.
    @property void cacheable(bool cacheable)
    {
        _cacheable = cacheable;
    }

    /// EXPERIMENTAL: Trigger wait-for-ready or not on this request.
    /// See https://github.com/grpc/grpc/blob/master/doc/wait-for-ready.md.
    /// If set, if an RPC is made when a channel's connectivity state is
    /// TRANSIENT_FAILURE or CONNECTING, the call will not "fail fast",
    /// and the channel will wait until the channel is READY before making the
    /// call.
    @property void waitForReady(bool waitForReady)
    {
        _waitForReady = waitForReady;
        _waitForReadyExplicitlySet = true;
    }

    /// Set the per call authority header (see
    /// https://tools.ietf.org/html/rfc7540#section-8.1.2.3).
    @property void authority(string authority)
    {
        _authority = authority;
    }

    /// Return the authentication context for this client call.
    ///
    /// \see grpc::AuthContext.
    AuthContext authContext() const
    {
        if (_authContext is null)
            _authContext = CreateAuthContext(_call);

        return _authContext;
    }

    /// Set credentials for the client call.
    ///
    /// A credentials object encapsulates all the state needed by a client to
    /// authenticate with a server and make various assertions, e.g., about the
    /// client’s identity, role, or whether it is authorized to make a particular
    /// call.
    ///
    /// \see  https://grpc.io/docs/guides/auth.html
    @property void credentials(CallCredentials credentials)
    {
        _credentials = credentials;
    }

    /// Return the compression algorithm the client call will request be used.
    /// Note that the gRPC runtime may decide to ignore this request, for example,
    /// due to resource constraints.
    @property CompressionAlgorithm compressionAlgorithm() const
    {
        return _compressionAlgorithm;
    }

    /// Set \a algorithm to be the compression algorithm used for the client call.
    ///
    /// \param algorithm The compression algorithm used for the client call.
    @property void compressionAlgorithm(CompressionAlgorithm compressionAlgorithm)
    {
    }

    /// Flag whether the initial metadata should be \a corked
    ///
    /// If \a corked is true, then the initial metadata will be coalesced with the
    /// write of first message in the stream. As a result, any tag set for the
    /// initial metadata operation (starting a client-streaming or bidi-streaming
    /// RPC) will not actually be sent to the completion queue or delivered
    /// via Next.
    ///
    /// \param corked The flag indicating whether the initial metadata is to be
    /// corked or not.
    @property void initialMetadataCorked(bool corked)
    {
        _initialMetadataCorked = corked;
    }

    /// Return the peer uri in a string.
    ///
    /// \warning This value is never authenticated or subject to any security
    /// related code. It must not be used for any authentication related
    /// functionality. Instead, use auth_context.
    ///
    /// \return The call's peer URI.
    string peer() const
    {
    }

    /// Get and set census context.
    @property void CensusContext(CensusContext censusContext)
    {
        _censusContext = censusContext;
    }

    @property CensusContext censusContext() const
    {
        return _censusContext;
    }

    /// Send a best-effort out-of-band cancel on the call associated with
    /// this client context.  The call could be in any stage; e.g., if it is
    /// already finished, it may still return success.
    ///
    /// There is no guarantee the call will be cancelled.
    ///
    /// Note that TryCancel() does not change any of the tags that are pending
    /// on the completion queue. All pending tags will still be delivered
    /// (though their ok result may reflect the effect of cancellation).
    void tryCancel()
    {
    }

    /// Global Callbacks
    ///
    /// Can be set exactly once per application to install hooks whenever
    /// a client context is constructed and destructed.
    interface GlobalCallbacks
    {
    public:
        void defaultConstructor(ClientContext context);
        void destructor(ClientContext context);
    }

    @property static void globalCallbacks(GlobalCallbacks callbacks);

    /// Should be used for framework-level extensions only.
    /// Applications never need to call this method.
    grpc_call* c_call()
    {
        return _call;
    }

    /// EXPERIMENTAL debugging API
    ///
    /// if status is not ok() for an RPC, this will return a detailed string
    /// of the gRPC Core error that led to the failure. It should not be relied
    /// upon for anything other than gaining more debug data in failure cases.
    @property string debugErrorString() const
    {
        return _debugErrorString;
    }

private:
    // Used by friend class CallOpClientRecvStatus
    @property void debugErrorString(string debugErrorString)
    {
        _debugErrorString = debugErrorString;
    }

    @property grpc_call* call() const
    {
        return _call;
    }

    void setCall(grpc_call* call, Channel channel);

    uint32_t initial_metadata_flags() const
    {
        return (idempotent_ ? GRPC_INITIAL_METADATA_IDEMPOTENT_REQUEST : 0) | (
                wait_for_ready_ ? GRPC_INITIAL_METADATA_WAIT_FOR_READY
                : 0) | (cacheable_ ? GRPC_INITIAL_METADATA_CACHEABLE_REQUEST
                : 0) | (wait_for_ready_explicitly_set_
                ? GRPC_INITIAL_METADATA_WAIT_FOR_READY_EXPLICITLY_SET
                : 0) | (initial_metadata_corked_ ? GRPC_INITIAL_METADATA_CORKED : 0);
    }

    @property string authority()
    {
        return _authority;
    }

    bool _initialMetadataReceived;
    bool _waitForReady;
    bool _waitForReadyExplicitlySet;
    bool _idempotent;
    bool _cacheable;
    Channel _channel;
    grpc_call* _call;
    bool _callCanceled;
    gpr_timespec deadline_;
    string _authority;
    CallCredentials _credentials;
    AuthContext _authContext;
    CensusContext* _censusContext;
    string[][string] _sendInitialMetadata;
    MetadataMap _recvInitialMetadata_;
    MetadataMap _trailingMetadata;

    grpc_call* _propagateFromCall;
    PropagationOptions _propagationOptions;

    CompressionAlgorithm _compressionAlgorithm;
    bool _initialMetadataCorked;

    string _debugErrorString;
}
