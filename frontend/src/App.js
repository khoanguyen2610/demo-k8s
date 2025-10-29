import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [health, setHealth] = useState(null);

  const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://add028c43610442de9fe7aac33dc601d-629592594.ap-southeast-1.elb.amazonaws.com';

  // Fetch health status
  const fetchHealth = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/health`);
      if (!response.ok) throw new Error('Health check failed');
      const data = await response.json();
      setHealth(data);
    } catch (err) {
      console.error('Health check error:', err);
    }
  };

  // Fetch users
  const fetchUsers = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/users`);
      if (!response.ok) throw new Error('Failed to fetch users');
      const data = await response.json();
      setUsers(data.users || []);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHealth();
    fetchUsers();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleRefresh = () => {
    fetchUsers();
  };

  return (
    <div className="App">
      <div className="container">
        <header className="header">
          <h1>👥 User Management</h1>
          <p className="subtitle">Powered by Go API + React</p>
          {health && (
            <div className="health-status">
              <span className="status-indicator"></span>
              <span>API Status: {health.status}</span>
              <span className="uptime">Uptime: {health.uptime}</span>
            </div>
          )}
        </header>

        <div className="controls">
          <button onClick={handleRefresh} className="refresh-button" disabled={loading}>
            {loading ? '🔄 Loading...' : '🔄 Refresh Users'}
          </button>
          <div className="user-count">
            Total Users: <strong>{users.length}</strong>
          </div>
        </div>

        {error && (
          <div className="error-message">
            ⚠️ Error: {error}
          </div>
        )}

        {loading ? (
          <div className="loading">
            <div className="spinner"></div>
            <p>Loading users...</p>
          </div>
        ) : (
          <div className="users-grid">
            {users.map((user) => (
              <div key={user.id} className="user-card">
                <div className="user-avatar">
                  {user.name.charAt(0).toUpperCase()}
                </div>
                <div className="user-info">
                  <h3 className="user-name">{user.name}</h3>
                  <p className="user-email">📧 {user.email}</p>
                  <div className="user-details">
                    <span className="detail-item">🎂 {user.age} years</span>
                    <span className="detail-item">🌍 {user.country}</span>
                  </div>
                  <p className="user-created">
                    Joined: {new Date(user.created_at).toLocaleDateString()}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}

        {!loading && users.length === 0 && !error && (
          <div className="empty-state">
            <p>No users found. Click refresh to load users.</p>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;

