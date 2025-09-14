#include <iostream>
#include <thread>

static void myThread()
{
    std::cout << "Thread started\n";
    std::this_thread::sleep_for(std::chrono::seconds(1));
    std::cout << "Thread done\n";
}

int main()
{
    std::cout << "Creating thread\n";
    auto thread = std::thread(myThread);
    std::cout << "Joining thread\n";
    thread.join();
    std::cout << "Thread joined\n";
    return 0;
}

