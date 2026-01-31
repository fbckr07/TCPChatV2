using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Eldoran.Chat;

public class TCPServer : IDisposable
{
    private static Socket? serverSocket;
    private static readonly int port = 21443;
    private static readonly int maxConnections = 100;
    private readonly CancellationTokenSource cancellationTokenSource = new();
    private readonly List<Task> clientTasks = new();
    private readonly object lockObject = new();
    private bool disposed = false;

    public async Task RunServerAsync()
    {
        try
        {
            Console.Clear();
            Console.SetCursorPosition(0, 0);
            
            serverSocket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            serverSocket.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, true);
            serverSocket.Bind(new IPEndPoint(IPAddress.Any, port));
            serverSocket.Listen(10);

            Console.WriteLine($"Server started on port {port}. Waiting for clients...");

            await AcceptClientsAsync(cancellationTokenSource.Token);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Server error: {ex.Message}");
        }
    }

    private async Task AcceptClientsAsync(CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            try
            {
                if (ChatServer.clients.Count >= maxConnections)
                {
                    await Task.Delay(100, cancellationToken);
                    continue;
                }

                Socket clientSocket = await AcceptAsync(serverSocket!, cancellationToken);
                
                lock (lockObject)
                {
                    ChatServer.clients.Add(clientSocket);
                }

                Console.WriteLine($"Client connected: {clientSocket.RemoteEndPoint} (Total: {ChatServer.clients.Count})");

                // Start handling the client in a separate task
                var clientTask = HandleClientAsync(clientSocket, cancellationToken);
                
                lock (lockObject)
                {
                    clientTasks.Add(clientTask);
                }

                // Clean up completed tasks periodically
                CleanupCompletedTasks();
            }
            catch (ObjectDisposedException)
            {
                break;
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error accepting client: {ex.Message}");
                await Task.Delay(1000, cancellationToken);
            }
        }
    }

    private static async Task<Socket> AcceptAsync(Socket serverSocket, CancellationToken cancellationToken)
    {
        return await Task.Run(() =>
        {
            while (!cancellationToken.IsCancellationRequested)
            {
                try
                {
                    return serverSocket.Accept();
                }
                catch (SocketException ex) when (ex.SocketErrorCode == SocketError.WouldBlock)
                {
                    Thread.Sleep(10);
                    continue;
                }
            }
            throw new OperationCanceledException();
        }, cancellationToken);
    }

    private async Task HandleClientAsync(Socket clientSocket, CancellationToken cancellationToken)
    {
        try
        {
            await ReceiveMessageAsync(clientSocket, cancellationToken);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error handling client {clientSocket.RemoteEndPoint}: {ex.Message}");
        }
        finally
        {
            RemoveClient(clientSocket);
        }
    }

    public static async Task ReceiveMessageAsync(Socket clientSocket, CancellationToken cancellationToken = default)
    {
        byte[] buffer = new byte[4096];

        try
        {
            while (!cancellationToken.IsCancellationRequested && clientSocket.Connected)
            {
                int bytesRead = await ReceiveAsync(clientSocket, buffer, cancellationToken);
                
                if (bytesRead == 0)
                {
                    Console.WriteLine($"Client disconnected: {clientSocket.RemoteEndPoint}");
                    break;
                }

                string message = Encoding.UTF8.GetString(buffer, 0, bytesRead);
                
                if (string.IsNullOrWhiteSpace(message))
                    continue;

                Console.WriteLine($"Received from {clientSocket.RemoteEndPoint}: {message}");
                await BroadcastMessageAsync(message, clientSocket);
            }
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine($"Client connection cancelled: {clientSocket.RemoteEndPoint}");
        }
        catch (SocketException ex)
        {
            Console.WriteLine($"Socket error for {clientSocket.RemoteEndPoint}: {ex.Message}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error receiving message from {clientSocket.RemoteEndPoint}: {ex.Message}");
        }
    }

    private static async Task<int> ReceiveAsync(Socket socket, byte[] buffer, CancellationToken cancellationToken)
    {
        return await Task.Run(() =>
        {
            try
            {
                return socket.Receive(buffer, SocketFlags.None);
            }
            catch (SocketException ex) when (ex.SocketErrorCode == SocketError.ConnectionReset || 
                                           ex.SocketErrorCode == SocketError.ConnectionAborted)
            {
                return 0;
            }
        }, cancellationToken);
    }

    static async Task BroadcastMessageAsync(string message, Socket senderSocket)
    {
        if (string.IsNullOrWhiteSpace(message))
            return;

        byte[] messageBytes = Encoding.UTF8.GetBytes(message);
        var clientsCopy = new List<Socket>();

        lock (ChatServer.clients)
        {
            clientsCopy.AddRange(ChatServer.clients);
        }

        var broadcastTasks = new List<Task>();

        foreach (var client in clientsCopy)
        {
            if (client != senderSocket && client.Connected)
            {
                broadcastTasks.Add(SendMessageAsync(client, messageBytes));
            }
        }

        await Task.WhenAll(broadcastTasks);
    }

    private static async Task SendMessageAsync(Socket client, byte[] messageBytes)
    {
        try
        {
            await Task.Run(() => client.Send(messageBytes, SocketFlags.None));
        }
        catch (SocketException ex)
        {
            Console.WriteLine($"Failed to send message to {client.RemoteEndPoint}: {ex.Message}");
            RemoveClient(client);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error sending message: {ex.Message}");
        }
    }

    private static void RemoveClient(Socket clientSocket)
    {
        bool removed = false;
        lock (ChatServer.clients)
        {
            removed = ChatServer.clients.Remove(clientSocket);
        }
        try
        {
            if (clientSocket.Connected)
            {
                try
                {
                    clientSocket.Shutdown(SocketShutdown.Both);
                }
                catch (SocketException) { /* ignore */ }
                catch (ObjectDisposedException) { /* ignore */ }
            }
            clientSocket.Close();
        }
        catch (ObjectDisposedException) { /* ignore */ }
        catch (Exception ex)
        {
            Console.WriteLine($"Error closing client socket: {ex.Message}");
        }
        if (removed)
        {
            try
            {
                Console.WriteLine($"Client removed: {(clientSocket?.RemoteEndPoint?.ToString() ?? "unknown")} (Remaining: {ChatServer.clients.Count})");
            }
            catch (ObjectDisposedException) { /* ignore */ }
        }
    }

    private void CleanupCompletedTasks()
    {
        lock (lockObject)
        {
            clientTasks.RemoveAll(task => task.IsCompleted);
        }
    }

    public void Stop()
    {
        cancellationTokenSource.Cancel();

        serverSocket?.Close();

        Task.WaitAll(clientTasks.ToArray(), TimeSpan.FromSeconds(5));

        lock (ChatServer.clients)
        {
            foreach (var client in ChatServer.clients.ToArray())
            {
                RemoveClient(client);
            }
        }
    }

    public void Dispose()
    {
        if (!disposed)
        {
            Stop();
            cancellationTokenSource.Dispose();
            disposed = true;
        }
    }
}