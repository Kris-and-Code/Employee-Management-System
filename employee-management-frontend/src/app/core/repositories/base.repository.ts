import { Observable } from 'rxjs';
import { ApiResponse, PaginationParams } from '../models';

export interface IRepository<T, ID = number> {
  getAll(params?: PaginationParams): Observable<ApiResponse<T[]>>;
  getById(id: ID): Observable<ApiResponse<T>>;
  create(entity: Partial<T>): Observable<ApiResponse<T>>;
  update(id: ID, entity: Partial<T>): Observable<ApiResponse<T>>;
  delete(id: ID): Observable<ApiResponse<void>>;
}

export abstract class BaseRepository<T, ID = number> implements IRepository<T, ID> {
  constructor(protected baseUrl: string) {}

  abstract getAll(params?: PaginationParams): Observable<ApiResponse<T[]>>;
  abstract getById(id: ID): Observable<ApiResponse<T>>;
  abstract create(entity: Partial<T>): Observable<ApiResponse<T>>;
  abstract update(id: ID, entity: Partial<T>): Observable<ApiResponse<T>>;
  abstract delete(id: ID): Observable<ApiResponse<void>>;
}
