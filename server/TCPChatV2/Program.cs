// TCPChatV2
//20082025 Eldoran

using System;
using System.Net.Sockets;
using System.Threading.Tasks;

namespace Eldoran.Chat;

public class ChatServer
{
    private static TCPServer? server;
    public static List<Socket> clients = new List<Socket>();

    public static async Task Main(string[] args)
    {
        Console.WriteLine("Starting TCP Chat Server...");
        server = new TCPServer();

        
        Console.CancelKeyPress += (sender, e) =>
        {
            e.Cancel = true; // Prevent the process from terminating.
            OnStop();
        };


        await server.RunServerAsync();

        

    }

    static void OnStop()
    {
        Console.WriteLine("Stopping server...");
        server?.Dispose();
    }
}