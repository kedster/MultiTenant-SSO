/**
 * API Client
 * Handles communication with OpenAuth backend
 */

import axios, { AxiosInstance } from 'axios';

class APIClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: import.meta.env.VITE_API_URL || 'http://localhost:8787',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add token to requests if available
    this.client.interceptors.request.use((config) => {
      const token = localStorage.getItem('accessToken');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
      return config;
    });

    // Handle token refresh on 401
    this.client.interceptors.response.use(
      (response) => response,
      async (error) => {
        if (error.response?.status === 401) {
          // TODO: Implement token refresh logic
          localStorage.removeItem('accessToken');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  // Auth endpoints
  async login(email: string, password: string) {
    const response = await this.client.post('/auth/login', { email, password });
    return response.data;
  }

  async logout() {
    const response = await this.client.post('/auth/logout');
    localStorage.removeItem('accessToken');
    return response.data;
  }

  async refreshToken() {
    const response = await this.client.post('/auth/refresh');
    return response.data;
  }

  // Organization endpoints
  async getOrganizations(page: number = 1, limit: number = 50) {
    const response = await this.client.get('/admin/orgs', { params: { page, limit } });
    return response.data;
  }

  async getOrganization(orgId: string) {
    const response = await this.client.get(`/admin/orgs/${orgId}`);
    return response.data;
  }

  async updateOrganization(orgId: string, updates: any) {
    const response = await this.client.put(`/admin/orgs/${orgId}`, updates);
    return response.data;
  }

  async deleteOrganization(orgId: string) {
    const response = await this.client.delete(`/admin/orgs/${orgId}`);
    return response.data;
  }

  // User endpoints
  async getUsers(page: number = 1, limit: number = 50) {
    const response = await this.client.get('/admin/users', { params: { page, limit } });
    return response.data;
  }

  async getUser(userId: string) {
    const response = await this.client.get(`/admin/users/${userId}`);
    return response.data;
  }

  async inviteUser(email: string, orgId: string, roles: string[]) {
    const response = await this.client.post('/admin/users/invite', { email, orgId, roles });
    return response.data;
  }

  async updateUser(userId: string, updates: any) {
    const response = await this.client.put(`/admin/users/${userId}`, updates);
    return response.data;
  }

  async deleteUser(userId: string) {
    const response = await this.client.delete(`/admin/users/${userId}`);
    return response.data;
  }

  // App access endpoints
  async getOrgApps(orgId: string) {
    const response = await this.client.get(`/admin/orgs/${orgId}/apps`);
    return response.data;
  }

  async setAppAccess(orgId: string, appId: string, enabled: boolean) {
    const response = await this.client.post(`/admin/orgs/${orgId}/apps`, { appId, enabled });
    return response.data;
  }
}

export const apiClient = new APIClient();
