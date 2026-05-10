#ifndef PLAYER_EVENTS_H
#define PLAYER_EVENTS_H

#include <queue>
#include <mutex>
#include <condition_variable>
#include <string>
#include <atomic>

enum class PlayerEventType {
    TRACK_ENDED,
    SEEK_COMPLETED,
    ERROR,
    TRACK_TRANSITION,
    NEXT_TRACK_FAILED
};

struct PlayerEvent {
    PlayerEventType type;
    int64_t int64Param = 0;
    int intParam = 0;
    std::string stringParam1;
    std::string stringParam2;

    PlayerEvent(PlayerEventType t) : type(t) {}

    static PlayerEvent trackEnded() {
        return PlayerEvent(PlayerEventType::TRACK_ENDED);
    }

    static PlayerEvent seekCompleted(int64_t position) {
        PlayerEvent event(PlayerEventType::SEEK_COMPLETED);
        event.int64Param = position;
        return event;
    }

    static PlayerEvent error(int code, const std::string& message) {
        PlayerEvent event(PlayerEventType::ERROR);
        event.intParam = code;
        event.stringParam1 = message;
        return event;
    }

    static PlayerEvent trackTransition(const std::string& from, const std::string& to) {
        PlayerEvent event(PlayerEventType::TRACK_TRANSITION);
        event.stringParam1 = from;
        event.stringParam2 = to;
        return event;
    }

    static PlayerEvent nextTrackFailed(const std::string& trackId, const std::string& error) {
        PlayerEvent event(PlayerEventType::NEXT_TRACK_FAILED);
        event.stringParam1 = trackId;
        event.stringParam2 = error;
        return event;
    }
};

class PlayerEventQueue {
public:
    void push(PlayerEvent event) {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_.push(std::move(event));
        cv_.notify_one();
    }

    bool pop(PlayerEvent& event, int timeoutMs = -1) {
        std::unique_lock<std::mutex> lock(mutex_);

        if (timeoutMs < 0) {
            cv_.wait(lock, [this] { return !queue_.empty() || shutdown_; });
        } else {
            cv_.wait_for(lock, std::chrono::milliseconds(timeoutMs),
                         [this] { return !queue_.empty() || shutdown_; });
        }

        if (shutdown_ && queue_.empty()) {
            return false;
        }

        if (queue_.empty()) {
            return false;
        }

        event = std::move(queue_.front());
        queue_.pop();
        return true;
    }

    void shutdown() {
        std::lock_guard<std::mutex> lock(mutex_);
        shutdown_ = true;
        cv_.notify_all();
    }

    void clear() {
        std::lock_guard<std::mutex> lock(mutex_);
        while (!queue_.empty()) {
            queue_.pop();
        }
    }

    bool isShutdown() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return shutdown_;
    }

private:
    std::queue<PlayerEvent> queue_;
    mutable std::mutex mutex_;
    std::condition_variable cv_;
    bool shutdown_ = false;
};

#endif // PLAYER_EVENTS_H