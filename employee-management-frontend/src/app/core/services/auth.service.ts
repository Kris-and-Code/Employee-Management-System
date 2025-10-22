import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { map, tap } from 'rxjs/operators';
import { User, UserRole } from '../models';
import { HttpService } from './http.service';

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  user: User;
  token: string;
  expiresIn: number;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();

  private tokenKey = 'auth_token';
  private userKey = 'current_user';

  constructor(private httpService: HttpService) {
    this.loadStoredUser();
  }

  login(credentials: LoginRequest): Observable<LoginResponse> {
    return this.httpService.post<LoginResponse>('auth/login', credentials)
      .pipe(
        map(response => response.data),
        tap(response => {
          this.setToken(response.token);
          this.setCurrentUser(response.user);
        })
      );
  }

  logout(): void {
    this.removeToken();
    this.setCurrentUser(null);
  }

  isAuthenticated(): boolean {
    const token = this.getToken();
    return !!token && !this.isTokenExpired(token);
  }

  hasRole(role: UserRole): boolean {
    const user = this.currentUserSubject.value;
    return user?.role === role;
  }

  hasAnyRole(roles: UserRole[]): boolean {
    const user = this.currentUserSubject.value;
    return user ? roles.includes(user.role) : false;
  }

  isAdmin(): boolean {
    return this.hasRole(UserRole.Admin);
  }

  isManager(): boolean {
    return this.hasAnyRole([UserRole.Admin, UserRole.Manager]);
  }

  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  private setToken(token: string): void {
    localStorage.setItem(this.tokenKey, token);
  }

  private removeToken(): void {
    localStorage.removeItem(this.tokenKey);
  }

  private setCurrentUser(user: User | null): void {
    this.currentUserSubject.next(user);
    if (user) {
      localStorage.setItem(this.userKey, JSON.stringify(user));
    } else {
      localStorage.removeItem(this.userKey);
    }
  }

  private loadStoredUser(): void {
    const storedUser = localStorage.getItem(this.userKey);
    const token = this.getToken();
    
    if (storedUser && token && !this.isTokenExpired(token)) {
      try {
        const user = JSON.parse(storedUser);
        this.currentUserSubject.next(user);
      } catch (error) {
        console.error('Error parsing stored user:', error);
        this.logout();
      }
    } else {
      this.logout();
    }
  }

  private isTokenExpired(token: string): boolean {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      const currentTime = Date.now() / 1000;
      return payload.exp < currentTime;
    } catch (error) {
      return true;
    }
  }

  refreshToken(): Observable<LoginResponse> {
    return this.httpService.post<LoginResponse>('auth/refresh', {})
      .pipe(
        map(response => response.data),
        tap(response => {
          this.setToken(response.token);
          this.setCurrentUser(response.user);
        })
      );
  }

  changePassword(oldPassword: string, newPassword: string): Observable<any> {
    return this.httpService.post('auth/change-password', {
      oldPassword,
      newPassword
    });
  }
}
