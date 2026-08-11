/// The call-status vocabulary, in one place.
///
/// These sets were written out four separate times across the FCM service and
/// the call service, each with a comment asking whoever came next to keep
/// them in lockstep. They had already drifted: one of the four quietly
/// included 'accepted' and the others did not.
///
/// Drift here is not cosmetic. Every one of these sets answers "is this call
/// over?", and the copies are read by different isolates on different
/// threads. A status missing from one of them is a call that tears down on
/// one path and lingers on another — which is the shape of nearly every call
/// bug worth chasing.
library;

/// Statuses that mean the call itself is finished.
///
/// 'accepted' is deliberately absent: a call that was answered is beginning,
/// not ending. Nor is 'participant_left', which is one person leaving a group
/// call the others are still on, nor its opposite 'participant_joined', which
/// is somebody walking into a call from the group chat, nor 'reconnect',
/// which is a request to rebuild the media rather than a state at all.
const Set<String> kTerminalCallStatuses = {
  'rejected',
  'declined',
  'busy',
  'cancelled',
  'ended',
  'missed',
  'failed',
};

/// Statuses that mean the phone should stop ringing.
///
/// A superset of the terminal ones plus 'accepted' — answering ends the ring
/// as surely as declining does, and anything watching a ring (a stashed
/// notification, a pending navigation) has to clear on both.
const Set<String> kRingOverStatuses = {
  ...kTerminalCallStatuses,
  'accepted',
};

/// True when [status] means the call is over. Case- and null-tolerant,
/// because these arrive from push payloads and sockets, not from Dart.
bool isTerminalCallStatus(Object? status) =>
    kTerminalCallStatuses.contains(status?.toString().toLowerCase().trim());

/// True when [status] means the ring should stop, answered or not.
bool isRingOverStatus(Object? status) =>
    kRingOverStatuses.contains(status?.toString().toLowerCase().trim());
